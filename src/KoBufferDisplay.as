const float TAU = 6.283185307179586;

namespace KoBuffer {
    void Main() {
        dev_trace("KoBuffer::Main");
        startnew(InitCoro);
    }

    void InitCoro() {
        dev_trace("KoBuffer::InitCoro");
        startnew(MainCoro);
        _S_TA_PriorPriorities[0] = S_TA_Priority1Type;
        _S_TA_PriorPriorities[1] = S_TA_Priority2Type;
        _S_TA_PriorPriorities[2] = S_TA_Priority3Type;
        OnSettingsChanged();
        startnew(Updates::MarkAllReadOnFirstBoot);
    }

    void MainCoro() {
        dev_trace("KoBuffer::MainCoro");
        while (true) {
            yield();
            CheckGMChange();
            CheckMapChange();
        }
    }

    string lastGM = "nonexistent init";
    void CheckGMChange() {
        if (CurrentGameMode != lastGM) {
            lastGM = CurrentGameMode;
            dev_trace("Set game mode: " + lastGM);
            KoBufferUI::Reset_TA();
        }
    }

    string lastMap;
    void CheckMapChange() {
        string newMap = GetApp().RootMap is null ? "" : GetApp().RootMap.MapInfo.MapUid;
        if (newMap != lastMap) {
            lastMap = newMap;
            KoBufferUI::Reset_TA();
        }
    }

    string get_CurrentGameMode() {
        auto app = cast<CTrackMania>(GetApp());
        auto serverInfo = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
        if (serverInfo is null) return "";
        return serverInfo.CurGameModeStr;
    }

    bool get_IsGameModeCotdKO() {
        return lastGM == "TM_KnockoutDaily_Online"
            || lastGM == "TM_Knockout_Debug"
            || lastGM == "TM_Knockout_Online";
    }

    bool get_IsGameModeTA() {
        return lastGM == "TM_TimeAttack_Online"
            || (S_TA_ShowDuringCotdQuali && lastGM == "TM_TimeAttackDaily_Online")
            || lastGM == "TM_TimeAttack"
            || lastGM == "TM_TimeAttack_Debug"
            || (S_TA_ShowDuringLocalMode && lastGM == "TM_Campaign_Local")
            || (S_TA_ShowDuringLocalMode && lastGM == "TM_PlayMap_Local")
            ;
    }

    bool get_IsGameModeMM() {
        return lastGM == "TM_Teams_Matchmaking_Online";
    }

    bool get_IsGameModeRanked() {
        return lastGM == "TM_Teams_Matchmaking_Online"
            || lastGM == "TM_Teams_Online"
            ;
    }

    bool get_IsGameModeCotdQuali() {
        return lastGM == "TM_TimeAttackDaily_Online";
    }

    CSmPlayer@ Get_App_CurrPlayground_GameTerminal_GUIPlayer(CGameCtnApp@ app) {
        auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
        if (cp is null || cp.GameTerminals.Length < 1) return null;
        auto GameTerminal = cp.GameTerminals[0];
        if (GameTerminal is null) return null;
        return cast<CSmPlayer>(GameTerminal.GUIPlayer);
    }

    string Get_App_CurrPlayground_GameTerminal_GUIPlayerUserName(CGameCtnApp@ app) {
        auto GUIPlayer = Get_App_CurrPlayground_GameTerminal_GUIPlayer(app);
        if (GUIPlayer is null) return "";
        return GUIPlayer.User.Name;
    }

    string Get_GameTerminal_ControlledPlayer_UserName(CGameCtnApp@ app) {
        try {
            return app.CurrentPlayground.GameTerminals[0].ControlledPlayer.User.Name;
        } catch {
            return "";
        }
    }

    string Get_GameTerminal_Player_UserName(CGameCtnApp@ app) {
        try {
            return app.CurrentPlayground.GameTerminals[0].GUIPlayer.User.Name;
        } catch {}
        try {
            return app.CurrentPlayground.GameTerminals[0].ControlledPlayer.User.Name;
        } catch {
            return "";
        }
    }

    // CSmScriptPlayer@ Get_GUIPlayer_ScriptAPI(CGameCtnApp@ app) {
    //     auto GUIPlayer = Get_App_CurrPlayground_GameTerminal_GUIPlayer(app);
    //     if (GUIPlayer is null) return null;
    //     return cast<CSmScriptPlayer>(GUIPlayer.ScriptAPI);
    // }

    CSmPlayer@ Get_App_CurrPlayground_GameTerminal_ControlledPlayer(CGameCtnApp@ app) {
        auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
        if (cp is null || cp.GameTerminals.Length < 1) return null;
        auto GameTerminal = cp.GameTerminals[0];
        if (GameTerminal is null) return null;
        return cast<CSmPlayer>(GameTerminal.ControlledPlayer);
    }

    CSmScriptPlayer@ Get_ControlledPlayer_ScriptAPI(CGameCtnApp@ app) {
        try {
            auto ControlledPlayer = cast<CSmPlayer>(app.CurrentPlayground.GameTerminals[0].ControlledPlayer);
            if (ControlledPlayer is null) return null;
            return cast<CSmScriptPlayer>(ControlledPlayer.ScriptAPI);
        } catch {
            return null;
        }
    }

    CSmScriptPlayer@ Get_GUIPlayer_ScriptAPI(CGameCtnApp@ app) {
        try {
            auto GUIPlayer = cast<CSmPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer);
            if (GUIPlayer is null) return null;
            return cast<CSmScriptPlayer>(GUIPlayer.ScriptAPI);
        } catch {
            return null;
        }
    }

    int Get_Player_StartTime(CGameCtnApp@ app) {
        try {
            return Get_GUIPlayer_ScriptAPI(app).StartTime;
        } catch {}
        try {
            return Get_ControlledPlayer_ScriptAPI(app).StartTime;
        } catch {}
        return -1;
    }

    int GetCurrentRaceTime(CGameCtnApp@ app) {
        if (app.Network.PlaygroundClientScriptAPI is null) return 0;
        int gameTime = app.Network.PlaygroundClientScriptAPI.GameTime;
        int startTime = Get_Player_StartTime(GetApp());
        if (startTime < 0) return 0;
        return gameTime - startTime;
        // return Math::Abs(gameTime - startTime);  // when formatting via Time::Format, negative ints don't work.
    }

    // // a hacky way to tell if the interface is hidden
    // bool IsInterfaceHidden(CGameCtnApp@ app) {
    //     try {
    //         return Get_ControlledPlayer_ScriptAPI(app).CurrentRaceTime != GetCurrentRaceTime(app);
    //     } catch {
    //         return false;
    //     }
    // }

    CGamePlaygroundUIConfig::EUISequence GetUiSequence(CGameCtnApp@ app) {
        try {
            return app.Network.ClientManiaAppPlayground.UI.UISequence;
        } catch {
            return CGamePlaygroundUIConfig::EUISequence::None;
        }
    }

    bool get_IsUiSeqPlaying() {
        return GetUiSequence(GetApp()) == CGamePlaygroundUIConfig::EUISequence::Playing;
    }

    bool get_IsUiSeqFinish() {
        return GetUiSequence(GetApp()) == CGamePlaygroundUIConfig::EUISequence::Finish;
    }
}

namespace KoBufferUI {
    bool g_DisableTillNextGameStart = false;

    // const string menuIcon = Icons::ArrowsH;
    const string menuIcon = " Δt";

    // int bufferDisplayFont = nvg::LoadFont("DroidSans.ttf", true, true);

    void RenderMenu() {
        if (UI::MenuItem("\\$faa\\$s" + menuIcon + "\\$z " + Meta::ExecutingPlugin().Name, MenuShortcutStr, g_koBufferUIVisible)) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
    }

    void RenderMenuMain() {
        if (S_HideIncrediblyUsefulMenuBarItem) return;
        bool isShowing = false
            || (S_ShowBufferTimeInKO && KoBuffer::IsGameModeCotdKO)
            || (S_ShowBufferTimeInTA && KoBuffer::IsGameModeTA)
            || (S_ShowBufferTimeInMM && KoBuffer::IsGameModeMM)
            ;
        if (!isShowing) return;
        string shortcut = Setting_ShortcutKeyEnabled ? "\\$bbb (" + tostring(Setting_ShortcutKey) + ")" : "";
        if (UI::BeginMenu("\\$faa\\$s" + menuIcon + "\\$z " + Meta::ExecutingPlugin().Name + shortcut)) {
            if (KoBuffer::IsGameModeCotdKO) RenderKoMenuMainInner();
            else if (KoBuffer::IsGameModeTA) RenderTaMenuMainInner();
            else if (KoBuffer::IsGameModeMM) RenderMmMenuMainInner();
            else RenderUnknownMenuMainInner();
            // UI::Separator();
            // RenderMmMenuMainInner();
            UI::EndMenu();
        }
    }

    const string CurrentVisibilityStatus() {
        if (g_KoBufferUIHidden) return "Hidden";
        if (g_DisableTillNextGameStart) return "Hidden till restart";
        if (S_ShowOnlyWhenInterfaceHidden && S_ShowOnlyWhenInterfaceVisible) return "Conflicting Settings";
        if (S_ShowOnlyWhenInterfaceVisible) return "When UI Visible";
        if (S_ShowOnlyWhenInterfaceHidden) return "When UI Hidden";
        return "Visible";
    }

    void RenderGlobalMenuMainInner() {
        UI::Text("\\$bbb Global Options");
        if (UI::BeginMenu("Visibility      \\$888  " + CurrentVisibilityStatus())) {
            if (UI::MenuItem("Hide Till Next Game Launch?", "", g_DisableTillNextGameStart)) {
                g_DisableTillNextGameStart = !g_DisableTillNextGameStart;
            }
            if (UI::MenuItem("Hide Altogether?", "", g_KoBufferUIHidden)) {
                g_KoBufferUIHidden = !g_KoBufferUIHidden;
            }
            if (UI::MenuItem("Show only when UI Hidden?", "", S_ShowOnlyWhenInterfaceHidden)) {
                S_ShowOnlyWhenInterfaceHidden = !S_ShowOnlyWhenInterfaceHidden;
            }
            if (UI::MenuItem("Show only when UI Visible?", "", S_ShowOnlyWhenInterfaceVisible)) {
                S_ShowOnlyWhenInterfaceVisible = !S_ShowOnlyWhenInterfaceVisible;
            }
            if (UI::MenuItem("Hide when GPS active?", "", S_HideWhenGPSActive)) {
                S_HideWhenGPSActive = !S_HideWhenGPSActive;
            }
            UI::EndMenu();
        }
        string ftStatus = !S_ShowFinalTime ? "Disabled"
            : (S_FT_OnlyWhenInterfaceHidden ? "When UI Hidden" : "Always");
        if (UI::BeginMenu("Final Time  \\$888  " + ftStatus)) {
            if (UI::MenuItem("Visible?", "", S_ShowFinalTime)) {
                S_ShowFinalTime = !S_ShowFinalTime;
            }
            if (UI::MenuItem("Only when UI Hidden?", "", S_FT_OnlyWhenInterfaceHidden)) {
                S_FT_OnlyWhenInterfaceHidden = !S_FT_OnlyWhenInterfaceHidden;
            }
            if (UI::MenuItem("Show No-Respawn Time, Too?", "", S_FT_ShowNoRespawnTime)) {
                S_FT_ShowNoRespawnTime = !S_FT_ShowNoRespawnTime;
            }
            UI::EndMenu();
        }

        if (UI::MenuItem("Update Instantly when Players Respawn?", "", S_UpdateInstantRespawns))
            S_UpdateInstantRespawns = !S_UpdateInstantRespawns;

        UI::Separator();
    }

    void RenderKoMenuMainInner() {
        RenderGlobalMenuMainInner();
        UI::Text("\\$bbb KO / COTD Options");
        if (UI::BeginMenu("Disable Buffer Time during KO")) {
                bool disableNow = UI::MenuItem("Disable Now");
                AddSimpleTooltip("You will need to re-enable it for KO in 'Global' settings.");
                if (disableNow) S_ShowBufferTimeInKO = false;
            UI::EndMenu();
        }
        UI::Separator();

        if (UI::MenuItem("Show SAFE indicator in no-KO round?", "", Setting_SafeIndicatorInNoKO))
            Setting_SafeIndicatorInNoKO = !Setting_SafeIndicatorInNoKO;

        bool clickedSafe = UI::MenuItem("Show SAFE indicator when elimination impossible?", "", Setting_ShowSafeIndicatorEver);
        AddSimpleTooltip("Note: sometimes there is no valid player to compare against, and green 99.999 will show anyway.");
        if (clickedSafe)
            Setting_ShowSafeIndicatorEver = !Setting_ShowSafeIndicatorEver;

        if (UI::MenuItem("Show OUT indicator?", "", Setting_ShowOutIndicatorEver))
            Setting_ShowOutIndicatorEver = !Setting_ShowOutIndicatorEver;
    }

    void RenderMmMenuMainInner() {
        RenderGlobalMenuMainInner();
        UI::Text("\\$bbb MM / Ranked Options");
        if (UI::BeginMenu("Disable Buffer Time during MM")) {
            bool disableNow = UI::MenuItem("Disable Now");
            AddSimpleTooltip("You will need to re-enable it for TA in 'Global' settings.");
            if (disableNow) S_ShowBufferTimeInMM = false;
            UI::EndMenu();
        }

        if (UI::MenuItem("Show delta to MVP player? (secondary)", "", S_MM_ShowMvpDelta))
            S_MM_ShowMvpDelta = !S_MM_ShowMvpDelta;

        if (UI::MenuItem("Show MVP points delta? (round end)", "", S_MM_ShowMvpPointsDelta))
            S_MM_ShowMvpPointsDelta = !S_MM_ShowMvpPointsDelta;
    }

    void RenderTaMenuMainInner() {
        RenderGlobalMenuMainInner();
        UI::Text("\\$bbb Time Attack / Solo Options");
        if (UI::BeginMenu("Disable Buffer Time during TA")) {
            if (UI::MenuItem("Disable for COTD Quali"))
                S_TA_ShowDuringCotdQuali = false;
            AddSimpleTooltip("You will need to re-enable it for COTD Quali in 'TA / Solo' settings.");

            if (UI::MenuItem("Disable for Local Mode"))
                S_TA_ShowDuringLocalMode = false;
            AddSimpleTooltip("You will need to re-enable it for Local Mode in 'TA / Solo' settings.");

            bool disableNow = UI::MenuItem("Disable Now");
            AddSimpleTooltip("You will need to re-enable it for TA in 'Global' settings.");
            if (disableNow) S_ShowBufferTimeInTA = false;
            UI::EndMenu();
        }

        if (UI::MenuItem("Show Two Buf. Times?", "", S_TA_ShowTwoBufferTimes))
            S_TA_ShowTwoBufferTimes = !S_TA_ShowTwoBufferTimes;

        if (UI::MenuItem("Hide When Spectating?", "", S_TA_HideWhenSpectating))
            S_TA_HideWhenSpectating = !S_TA_HideWhenSpectating;

        if (UI::MenuItem("Update Timer Immediately?", "", S_TA_UpdateTimerImmediately))
            S_TA_UpdateTimerImmediately = !S_TA_UpdateTimerImmediately;

        if (UI::MenuItem("Show Vs. Time at Race Start?", "", S_TA_ShowFinalTimeAtStart))
            S_TA_ShowFinalTimeAtStart = !S_TA_ShowFinalTimeAtStart;

        UI::Separator();

        UI::Text("\\$bbb Current References:");
        UI::Text("\\$bbb  Priority 1: " + WrappedTimesLabel(priorityGhostRaw));
        UI::Text("\\$bbb  Priority 2: " + WrappedTimesLabel(secondaryGhostRaw));
        UI::Text("\\$bbb  Priority 3: " + WrappedTimesLabel(tertiaryGhostRaw));

        if (UI::BeginMenu("Priority 1: \\$bbb("+tostring(S_TA_Priority1Type)+")")) {
            DrawPriorityInner(1, S_TA_Priority1Type, S_TA_Priority1Type);
            UI::EndMenu();
        }
        if (UI::BeginMenu("Priority 2: \\$bbb("+tostring(S_TA_Priority2Type)+")")) {
            DrawPriorityInner(2, S_TA_Priority2Type, S_TA_Priority2Type);
            UI::EndMenu();
        }
        if (UI::BeginMenu("Priority 3: \\$bbb("+tostring(S_TA_Priority3Type)+")")) {
            DrawPriorityInner(3, S_TA_Priority3Type, S_TA_Priority3Type);
            UI::EndMenu();
        }
        UI::Separator();

        UpdateGhosts();

        if (UI::BeginMenu("Vs. Ghost Choice:  \\$bbb("+_ghosts.Length+")")) {
            bool choiceBestGhost = S_TA_GhostChoice == GhostChoice::BestGhost;
            if (UI::MenuItem("Best Ghost", "", choiceBestGhost)) {
                S_TA_GhostChoice = GhostChoice::BestGhost;
            }
            for (uint i = 0; i < _ghosts.Length; i++) {
                auto item = _ghosts[i];
                bool selected = item.Result_Time == S_TA_GhostTime && item.Nickname == S_TA_GhostName;
                if (UI::MenuItem(GhostInfoLabel(item), Time::Format(item.Result_Time), selected && !choiceBestGhost)) {
                    S_TA_GhostChoice = GhostChoice::NamedGhost;
                    S_TA_GhostName = item.Nickname;
                    S_TA_GhostTime = item.Result_Time;
                }
            }
            UI::EndMenu();
        }

        auto localPlay = GetApp().PlaygroundScript !is null;
        bool enabled = !localPlay && GetApp().CurrentPlayground !is null;
        auto rd = MLFeed::GetRaceData();
        uint nbPlayers = rd.SortedPlayers_TimeAttack.Length;
        if (UI::BeginMenu("Vs. Player Choice:  \\$bbb("+nbPlayers+")", enabled)) {
            string playersTime;
            const MLFeed::PlayerCpInfo@ playerInfo;
            for (uint i = 0; i < rd.SortedPlayers_TimeAttack.Length; i++) {
                auto item = rd.SortedPlayers_TimeAttack[i];
                bool selected = S_TA_VsPlayerName == item.name;
                @playerInfo = rd.GetPlayer(item.name);
                if (playerInfo is null) continue;
                bool piEnabled = playerInfo.bestTime > 0;
                playersTime = !piEnabled ? "" : Time::Format(Math::Max(playerInfo.bestTime, 0));
                if (UI::MenuItem(item.name, playersTime, selected, piEnabled)) {
                    S_TA_VsPlayerName = item.name;
                }
            }
            UI::EndMenu();
        }

    }

    void DrawPriorityInner(uint priority, TaBufferTimeType _S_Selected, TaBufferTimeType &out _S_Type) {
        for (uint i = 0; i < NbTaBufferTimeTypes; i++) {
            TaBufferTimeType type = TaBufferTimeType(i);
            string name = tostring(type);
            if (UI::MenuItem(name + "##" + priority, "", _S_Selected == type)) {
                _S_Type = type;
                startnew(OnSettingsChanged_TA_EnsureCorrectPriority);
            }
        }
    }

    const string FormatNameAndTime(const string &in name, uint time) {
        return name + " ("+Time::Format(time)+")";
    }

    const string WrappedTimesLabel(const WrappedTimes@ times) {
        return ((times is null || times.innerResultTime < 0) ? "null" : (FormatNameAndTime(times.ghostName, times.innerResultTime)));
    }

    const string GhostInfoLabel(const MLFeed::GhostInfo@ ghost) {
        return ((ghost is null) ? "null" : ghost.Nickname);
        // return ((ghost is null) ? "null" : (ghost.Nickname + " ("+Time::Format(ghost.Result_Time)+")"));
    }

    void RenderUnknownMenuMainInner() {
        UI::Text("\\$f84 Unknown Game Mode! " + KoBuffer::lastGM);
        UI::TextWrapped("You should never see this. Sorry.\nPlease submit a bug report including at least the game mode and your settings.");
    }

    int _preview_secondaryTimerTime = 0;
    int _preview_lastTime = 0;

    void ShowPreview(bool isSecondary = false) {
        int time = int(Time::Now);
        int secDelta = time - _preview_lastTime;
        _preview_lastTime = time;
        if (time % 2000 > 500) _preview_secondaryTimerTime += secDelta;
        time = isSecondary ? _preview_secondaryTimerTime : time;
        int msOffset = (time % 2000) - 1000;
        int cpOffset = Math::Abs((msOffset + 1000) / 400 - 2);
        bool isBehind = msOffset < 0;
        msOffset = Math::Abs(msOffset);
        DrawBufferTime(msOffset, isBehind, GetBufferTimeColor(cpOffset, isBehind), isSecondary);
    }

    CGamePlaygroundUIConfig::EUISequence currSeq = CGamePlaygroundUIConfig::EUISequence::None;
    CGamePlaygroundUIConfig::EUISequence lastUiSeq = CGamePlaygroundUIConfig::EUISequence::None;
    void Render() {
        if (S_ShowFinalTime_Preview) {
            RenderFinalTime();
        }
        if (S_ShowMvpDelta_Preview) {
            ShowMvpDeltaPreview();
        }
        // if (S_ShowTeamPoints_Preview) {
        //     ShowTeamPointsPreview();
        // }
        if (Setting_ShowPreview) {
            ShowPreview();
            if (Setting_ShowSecondaryPreview)
                ShowPreview(true);
            return;
        }

        if (g_DisableTillNextGameStart) return;

        auto nextUiSeq = KoBuffer::GetUiSequence(GetApp());
        if (nextUiSeq != currSeq) {
            lastUiSeq = currSeq;
            currSeq = nextUiSeq;
        }
        bool isPlaying = currSeq == CGamePlaygroundUIConfig::EUISequence::Playing;
        bool isFinish = currSeq == CGamePlaygroundUIConfig::EUISequence::Finish;
        bool isEndRound = currSeq == CGamePlaygroundUIConfig::EUISequence::EndRound;
        bool skipSequence = !isPlaying && !isFinish && !isEndRound;
        if (skipSequence) return;
        if (!g_koBufferUIVisible
            || (S_ShowOnlyWhenInterfaceHidden && UI::IsGameUIVisible())
            || (S_ShowOnlyWhenInterfaceVisible && !UI::IsGameUIVisible())
        ) {
            // if we reset here then the menu gives no feedback about the priorities of what references are used.
            // Reset_TA();
            return;
        }

        // modify isFinish here to account for spectating.
        isFinish = isFinish || (isPlaying && ta_playerTime !is null && uint(ta_playerTime.cpCount) == MLFeed::GetRaceData().CPsToFinish);
        if (isFinish) isPlaying = false;

        if (isPlaying && S_HideWhenGPSActive && IsGPSActive()) return;

        bool playerFinished = ta_playerTime is null ? false : uint(ta_playerTime.cpCount) == MLFeed::GetRaceData().CPsToFinish;
#if DEV
        // playerFinished = ta_playerTime !is null; // dev
#endif
        if (S_ShowFinalTime && (isFinish || (isPlaying && playerFinished))) {
            RenderFinalTime();
        }

        if (S_ShowBufferTimeInKO && KoBuffer::IsGameModeCotdKO)
            Render_KO(isPlaying, isFinish, isEndRound);
        else if (S_ShowBufferTimeInTA && KoBuffer::IsGameModeTA)
            Render_TA(isPlaying, isFinish, isEndRound);
        else if (S_ShowBufferTimeInMM && KoBuffer::IsGameModeMM)
            Render_MM(isPlaying, isFinish, isEndRound);
    }

    // track the ghosts we see and the map they're seen first on. should not be cleared.
    dictionary ghostFirstSeenMap;

    const string KeyForGhost(const MLFeed::GhostInfo@ g) {
        return g.Nickname + (g.Checkpoints.Length << 12 ^ g.Result_Time);
    }

    const string SeenGhostSaveMap(const MLFeed::GhostInfo@ g) {
        string key = KeyForGhost(g);
        if (!ghostFirstSeenMap.Exists(key)) {
            ghostFirstSeenMap[key] = GetApp().RootMap.MapInfo.MapUid;
        }
        return key;
    }

    const string GetGhostsMap(const string &in key) {
        string outStr;
        if (ghostFirstSeenMap.Get(key, outStr)) {
            return outStr;
        }
        return "";
    }

    WrapPlayerCpInfo@ ta_playerTime;
    WrapBestTimes@ ta_bestTime;
    WrapBestTimes@ ta_vsPlayer;
    WrapGhostInfo@ ta_bestGhost;
    WrapGhostInfo@ ta_pbGhost;
    WrappedTimes@ priorityGhost;
    WrappedTimes@ secondaryGhost;
    WrappedTimes@ tertiaryGhost;
    WrappedTimes@ priorityGhostRaw;
    WrappedTimes@ secondaryGhostRaw;
    WrappedTimes@ tertiaryGhostRaw;

    array<const MLFeed::GhostInfo@> _ghosts;
    uint lastNbGhosts = 0;
    dictionary seenGhosts;
    int highestGhostIdSeen = -1;

    void Reset_TA() {
        @ta_playerTime = null;
        @ta_bestTime = null;
        @ta_vsPlayer = null;
        @ta_bestGhost = null;
        @ta_pbGhost = null;
        @priorityGhost = null;
        @secondaryGhost = null;
        @tertiaryGhost = null;
        @priorityGhostRaw = null;
        @secondaryGhostRaw = null;
        @tertiaryGhostRaw = null;
        _ghosts.RemoveRange(0, _ghosts.Length);
        seenGhosts.DeleteAll();
        lastNbGhosts = 0;
        highestGhostIdSeen = -1;
    }

    uint lastWarnManyGhosts = 0;
    void WarnTooManyGhosts() {
        if (lastWarnManyGhosts + 20000 < Time::Now) {
            lastWarnManyGhosts = Time::Now;
            NotifyWarning("The game has loaded at least " + lastNbGhosts + " ghosts.\n\nThis can cause lag upon crossing the finish line.\n\nQuit and rejoin the server to fix (or ignore it).");
        }
    }

    bool UpdateGhosts() {
        if (GetApp().RootMap is null) return false;
        auto GD = MLFeed::GetGhostData();
        if (lastNbGhosts != GD.NbGhosts) {
            auto start_time = Time::Now;
            lastNbGhosts = GD.NbGhosts;
            if (lastNbGhosts > 200) {
                WarnTooManyGhosts();
            }
            // _ghosts.RemoveRange(0, _ghosts.Length);
            string key;
            for (uint i = 0; i < GD.Ghosts.Length; i++) {
                auto item = GD.Ghosts[i];
                // these always increase it seems... might be an issue in future but should be okay
                if (int(item.IdUint) <= highestGhostIdSeen) continue;
                highestGhostIdSeen = item.IdUint;
                key = SeenGhostSaveMap(item);
                if (seenGhosts.Exists(key)) continue;
                seenGhosts[key] = true;
                if (GetGhostsMap(key) != GetApp().RootMap.MapInfo.MapUid) continue;
                _ghosts.InsertLast(item);
            }
            if (Time::Now - start_time >= 2) {
                warn("UpdateGhosts took " + (Time::Now - start_time) + " ms!");
            }
            return true;
        }
        return false;
    }

    void Render_TA_StateDebugScreen() {
        if (!S_ShowDebug_TA_State) return;
        UI::SetNextWindowSize(400, 400, UI::Cond::Appearing);
        if (UI::Begin(Meta::ExecutingPlugin().Name + " - TA Debug", S_ShowDebug_TA_State)) {
            DrawDebug_WrappedTimes("ta_playerTime", ta_playerTime);
            DrawDebug_WrappedTimes("ta_bestTime", ta_bestTime);
            DrawDebug_WrappedTimes("ta_vsPlayer", ta_vsPlayer);
            DrawDebug_WrappedTimes("ta_bestGhost", ta_bestGhost);
            DrawDebug_WrappedTimes("ta_pbGhost", ta_pbGhost);
            UI::Separator();
            DrawDebug_WrappedTimes("priorityGhostRaw", priorityGhostRaw);
            DrawDebug_WrappedTimes("secondaryGhostRaw", secondaryGhostRaw);
            DrawDebug_WrappedTimes("tertiaryGhostRaw", tertiaryGhostRaw);
            UI::Separator();
            DrawDebug_WrappedTimes("priorityGhost", priorityGhost);
            DrawDebug_WrappedTimes("secondaryGhost", secondaryGhost);
            DrawDebug_WrappedTimes("tertiaryGhost", tertiaryGhost);
        }
        UI::End();
    }

    void DrawDebug_WrappedTimes(const string &in name, CPAbstraction@ wt) {
        UI::Text(name + ": " + (wt is null ? "null" :  wt.ToString()));
    }

    void RenderFinalTime() {
        DrawFinalTime();
    }

    enum GhostChoice {
        BestGhost,
        NamedGhost
    }

    [Setting hidden]
    GhostChoice S_TA_GhostChoice = GhostChoice::BestGhost;

    [Setting hidden]
    string S_TA_GhostName = "XertroV";

    [Setting hidden]
    int S_TA_GhostTime = 1337;

    [Setting hidden]
    string S_TA_VsPlayerName = "XertroV";

    // show buffer in TA against personal best
    void Render_TA(bool isPlaying, bool isFinish, bool isEndRound) {
        if (isEndRound) return;
        auto crt = KoBuffer::GetCurrentRaceTime(GetApp());

        auto raceData = MLFeed::GetRaceData_V2();
        auto playerName = KoBuffer::Get_GameTerminal_Player_UserName(GetApp());
        auto physicalPlayersName = KoBuffer::Get_GameTerminal_ControlledPlayer_UserName(GetApp());
        auto isSpectating = playerName != physicalPlayersName;
        if (S_TA_HideWhenSpectating && isSpectating) return;
        // trace(tostring(isSpectating));
        auto localPlayer = raceData.GetPlayer_V2(playerName);
        if (localPlayer is null) return;


        bool isUiSeqPlaying = currSeq == CGamePlaygroundUIConfig::EUISequence::Playing;
        bool isRaceStart = isUiSeqPlaying && KoBuffer::GetCurrentRaceTime(GetApp()) < 5000;  // first 5s only
        bool shouldUpdateGhosts = isUiSeqPlaying;
        const MLFeed::GhostInfo@ chosenGhost = null;
        // const MLFeed::GhostInfo@ bestGhost = null; // todo: mb track this too and default to it?
        const MLFeed::GhostInfo@ pbGhost = null;
        bool updateBestGhostNotChosen = S_TA_GhostChoice == GhostChoice::BestGhost;

        UpdateGhosts();

        if (shouldUpdateGhosts) {
            for (uint i = 0; i < _ghosts.Length; i++) {
                auto g = _ghosts[i];
                bool nameMatches = g.Nickname == playerName;
                bool namePb = g.Nickname.EndsWith("Personal best");

                // pb ghost
                bool checkGhostForPb = !isSpectating && (nameMatches || namePb);
                // look for best pb ghost
                if (checkGhostForPb && (pbGhost is null || (pbGhost.Result_Time > g.Result_Time))) {
                    @pbGhost = g;
                }

                // chosen ghost
                if (updateBestGhostNotChosen && !nameMatches && !namePb && (chosenGhost is null || chosenGhost.Result_Time > g.Result_Time))
                    @chosenGhost = g;
                else if (chosenGhost is null && g.Nickname == S_TA_GhostName && g.Result_Time == S_TA_GhostTime)
                    @chosenGhost = g;
            }
        }

        // if we fail to get a chosen ghost, reset to best ghost.
        if (updateBestGhostNotChosen && chosenGhost is null) {
            S_TA_GhostChoice = GhostChoice::BestGhost;
        }

        if (ta_playerTime is null) @ta_playerTime = WrapPlayerCpInfo(localPlayer);
        else ta_playerTime.UpdateFrom(localPlayer);

        // if the UI sequence isn't playing,
        // then we want to show the final time of the ghost
        // (i.e., as soon as the player finishes).
        if (!isUiSeqPlaying) {
            if (chosenGhost !is null) crt = Math::Max(crt, chosenGhost.Result_Time);
            if (pbGhost !is null) crt = Math::Max(crt, pbGhost.Result_Time);
            crt *= 2; // just to be sure.
        }

        auto vsPlayerTimes = MLFeed::GetPlayersBestTimes(S_TA_VsPlayerName);
        if (vsPlayerTimes !is null && vsPlayerTimes.Length > 0) {
            if (ta_vsPlayer is null) @ta_vsPlayer = WrapBestTimes(S_TA_VsPlayerName, vsPlayerTimes, crt, ta_playerTime.cpCount);
            else ta_vsPlayer.UpdateFrom(S_TA_VsPlayerName, vsPlayerTimes, crt, ta_playerTime.cpCount);
        } else if (ta_vsPlayer !is null) {
            ta_vsPlayer.UpdateFromCRT(crt, ta_playerTime.cpCount);
        }

        // don't call GetPlayersBestTimes when we're not updating ghosts to avoid loading the players best times immediately.
        if (shouldUpdateGhosts) {
            auto @playerBestTimes = MLFeed::GetPlayersBestTimes(playerName);
            if (playerBestTimes !is null && playerBestTimes.Length > 0) {
                if (ta_bestTime is null) @ta_bestTime = WrapBestTimes(playerName, playerBestTimes, crt, ta_playerTime.cpCount);
                else ta_bestTime.UpdateFrom(playerName, playerBestTimes, crt, ta_playerTime.cpCount);
            } else {
                @ta_bestTime = null;
            }
        } else if (ta_bestTime !is null && !ta_bestTime.IsEmpty) {
            // update without providing new CPs
            ta_bestTime.UpdateFromCRT(crt, ta_playerTime.cpCount);
        }

        if (ta_bestGhost is null) @ta_bestGhost = WrapGhostInfo(chosenGhost, crt, ta_playerTime.cpCount);
        else ta_bestGhost.UpdateFrom(chosenGhost, crt, ta_playerTime.cpCount);

        if (!isSpectating) {
            if (ta_pbGhost is null) @ta_pbGhost = WrapGhostInfo(pbGhost, crt, ta_playerTime.cpCount);
            else ta_pbGhost.UpdateFrom(pbGhost, crt, ta_playerTime.cpCount);
        } else {
            @ta_pbGhost = null;
        }

        @priorityGhostRaw = SelectBasedOnType(S_TA_Priority1Type);
        @secondaryGhostRaw = SelectBasedOnType(S_TA_Priority2Type);
        @tertiaryGhostRaw = SelectBasedOnType(S_TA_Priority3Type);
        @priorityGhost = priorityGhostRaw;
        @secondaryGhost = secondaryGhostRaw;
        @tertiaryGhost = tertiaryGhostRaw;

        if (priorityGhost is null || priorityGhost.IsEmpty) {
            if (secondaryGhost is null || secondaryGhost.IsEmpty) {
                if (tertiaryGhost is null || tertiaryGhost.IsEmpty) {
                    // 3 reference ghosts that are null/empty
                    return;
                }
                @priorityGhost = tertiaryGhost;
                @tertiaryGhost = null;
            } else {
                @priorityGhost = secondaryGhost;
                @secondaryGhost = tertiaryGhost;
            }
        }

        if (secondaryGhost is null || secondaryGhost.IsEmpty || priorityGhost == secondaryGhost) {
            @secondaryGhost = tertiaryGhost;
            @tertiaryGhost = null;
        }

        bool showTwoTimes = S_TA_ShowTwoBufferTimes && secondaryGhost !is null && not secondaryGhost.IsEmpty
            && (priorityGhost != secondaryGhost
                || (S_TA_ShowFinalTimeAtStart && priorityGhost.innerResultTime != secondaryGhost.innerResultTime)
            );

        bool showReferenceFinalTimes = S_TA_ShowFinalTimeAtStart && isRaceStart && IsPlayerStationary();

        if (showReferenceFinalTimes) {
            DrawReferenceFinalTime(priorityGhost.innerResultTime, S_TA_FinalRefTimeColor);
            if (showTwoTimes) {
                DrawReferenceFinalTime(secondaryGhost.innerResultTime, S_TA_FinalRefTimeColor, true);
            }
            return;
        }

        // priority ghost
        bool isBehind = ta_playerTime > priorityGhost;
        // print("ta_playerTime: " + ta_playerTime.ToString() + ", priorityGhost: " + priorityGhost.ToString() + ", isBehind: " + tostring(isBehind));
        auto msDelta = CalcMsDelta(ta_playerTime, isBehind, priorityGhost);
        uint cpDelta = Math::Abs(ta_playerTime.cpCount - priorityGhost.cpCount);
        DrawBufferTime(msDelta, isBehind, GetBufferTimeColor(cpDelta, isBehind));

        if (showTwoTimes) {
            isBehind = ta_playerTime > secondaryGhost;
            msDelta = CalcMsDelta(ta_playerTime, isBehind, secondaryGhost);
            cpDelta = Math::Abs(ta_playerTime.cpCount - secondaryGhost.cpCount);
            DrawBufferTime(msDelta, isBehind, GetBufferTimeColor(cpDelta, isBehind), true);
        }
    }

    WrappedTimes@ SelectBasedOnType(TaBufferTimeType type) {
        if (type == TaBufferTimeType::None) return null;
        if (type == TaBufferTimeType::VsGhost) return ta_bestGhost;
        if (type == TaBufferTimeType::YourBestTime) return ta_bestTime;
        if (type == TaBufferTimeType::YourPB) return ta_pbGhost;
        if (type == TaBufferTimeType::BestTimeOrPB) {
            WrappedTimes@ pb = ta_pbGhost;
            WrappedTimes@ bt = ta_bestTime;
            if (pb is null) return bt;
            if (bt is null) return pb;
            if (pb < bt) return pb;
            return bt;
        }
        if (type == TaBufferTimeType::VsPlayer) return ta_vsPlayer;
        NotifyError("Bug: invalid type. Please report this to @XertroV on Openplanet Discord.");
        throw("SelectBasedOnType invalid type");
        return null;
    }

    WrapPlayerCpInfo@ mm_targetTime;
    WrapPlayerCpInfo@ mm_mvpTime;

    void Render_MM_StateDebugScreen() {
        if (!S_ShowDebug_MM_State) return;
        UI::SetNextWindowSize(300, 200, UI::Cond::Appearing);
        if (UI::Begin(Meta::ExecutingPlugin().Name + " - MM Debug", S_ShowDebug_MM_State)) {
            DrawDebug_WrappedTimes("ta_playerTime", ta_playerTime);
            DrawDebug_WrappedTimes("mm_targetTime", mm_targetTime);
            DrawDebug_WrappedTimes("mm_mvpTime", mm_mvpTime);
            UI::Separator();
            UI::Text("mm_finishedTeamOrder: " + string::Join(IntsToStrs(mm_finishedTeamOrder), ", "));
            UI::Text("mm_points: " + string::Join(IntsToStrs(mm_points), ", "));
            UI::Text("mm_teamTotals: " + string::Join(IntsToStrs(mm_teamTotals), ", "));
            UI::Text("mm_inflectionIx: " + mm_inflectionIx);
            // DrawDebug_WrappedTimes("priorityGhostRaw", priorityGhostRaw);
            // DrawDebug_WrappedTimes("secondaryGhostRaw", secondaryGhostRaw);
            // DrawDebug_WrappedTimes("tertiaryGhostRaw", tertiaryGhostRaw);
            // UI::Separator();
            // DrawDebug_WrappedTimes("priorityGhost", priorityGhost);
            // DrawDebug_WrappedTimes("secondaryGhost", secondaryGhost);
            // DrawDebug_WrappedTimes("tertiaryGhost", tertiaryGhost);
        }
        UI::End();
    }

    int[] mm_finishedTeamOrder;
    int[] mm_points;
    int[] mm_teamTotals;
    int mm_inflectionIx = -1;

    void Render_MM(bool isPlaying, bool isFinish, bool isEndRound) {
        if (!KoBuffer::IsGameModeMM) return;

        auto raceData = MLFeed::GetRaceData_V3();
        auto teamsData = MLFeed::GetTeamsMMData_V1();

        if (teamsData.WarmUpIsActive
            || teamsData.RoundNumber < 1
            || teamsData.StartNewRace < 1
            || teamsData.PointsRepartition.Length == 0) {
            return;
        }

        // auto guiPlayer = KoBuffer::Get_App_CurrPlayground_GameTerminal_GUIPlayer(GetApp());
        // auto controlledPlayer = KoBuffer::Get_App_CurrPlayground_GameTerminal_ControlledPlayer(GetApp());

        auto @players = raceData.SortedPlayers_Race_Respawns;
        // int nbPlayers = raceData.SortedPlayers_Race_Respawns.Length;

        mm_finishedTeamOrder.RemoveRange(0, mm_finishedTeamOrder.Length);
        int playerIx = -1;
        // not really used atm
        int ctrlPlayerIx = -1;
        int mvpPlayerIx = -1;
        bool ctrlPlayerFinished = true;
        for (uint i = 0; i < players.Length; i++) {
            auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
            // if (player.Name == controlledPlayer.User.Name) playerIx = i;
            if (player.IsLocalPlayer) {
                ctrlPlayerIx = i;
                ctrlPlayerFinished = player.CpCount >= int(raceData.CPsToFinish);
            }
            if (player.Name == teamsData.MvpName) mvpPlayerIx = i;
            mm_finishedTeamOrder.InsertLast(player.TeamNum);
        }
        playerIx = ctrlPlayerIx;
        bool lastUiSeqEndRound = lastUiSeq == CGamePlaygroundUIConfig::EUISequence::EndRound;
        // mvp points delta
        if (ctrlPlayerFinished || isEndRound) { //  || guiPlayer is null
            // render team points, mvp delta
            auto blueScore = teamsData.ClanScores[1];
            auto redScore = teamsData.ClanScores[2];

            auto bluePoints = 0;
            auto redPoints = 0;
            auto mvpPoints = 0;
            auto mvpIx = -1;
            auto mvpNextPoints = 0;
            auto mvpNextIx = -1;
            auto playerPoints = 0;
            for (uint i = 0; i < players.Length; i++) {
                auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                auto roundPoints = (isEndRound || lastUiSeqEndRound) ? 0 : player.RoundPoints;
                auto totalPoints = player.Points + roundPoints;
                if (player.TeamNum == 1) bluePoints += player.RoundPoints;
                else redPoints += player.RoundPoints;
                if (totalPoints > mvpPoints) {
                    mvpNextPoints = mvpPoints;
                    mvpNextIx = mvpIx;
                    mvpPoints = totalPoints;
                    mvpIx = i;
                } else if (totalPoints > mvpNextPoints) {
                    mvpNextPoints = totalPoints;
                    mvpNextIx = i;
                }
                if (player.Name == MLFeed::LocalPlayersName) {
                    playerPoints = totalPoints;
                    playerIx = i;
                }
            }
            bool playerIsMvp = mvpIx == playerIx;
            auto mvpPointsTarget = playerIsMvp ? mvpNextPoints : mvpPoints;
            auto delta = Math::Abs(playerPoints - mvpPointsTarget);
            DrawMvpPointsDelta(delta, mvpPointsTarget > playerPoints);
        }


        teamsData.ComputePoints(mm_finishedTeamOrder, mm_points, mm_teamTotals);
        if (mm_points.Length != mm_finishedTeamOrder.Length) {
            warn('mm_points array and team array don\'t match');
            return;
        }

        if (playerIx < 0 || ctrlPlayerIx < 0) {
            warn('the gui player or local player was not found');
            return;
        }

        auto playersTeam = cast<MLFeed::PlayerCpInfo_V4>(players[playerIx]).TeamNum;
        auto nbPlayers = players.Length;
        auto otherTeam = playersTeam == 1 ? 2 : 1;
        // have to be ahead if we can draw, and there are no draws when unbalanced.
        auto teamWinning = mm_teamTotals[playersTeam] > mm_teamTotals[otherTeam]
            || (teamsData.TeamsUnbalanced && mm_teamTotals[playersTeam] == mm_teamTotals[otherTeam]
                && cast<MLFeed::PlayerCpInfo_V4>(players[0]).TeamNum == playersTeam);
        int dir = teamWinning ? 1 : -1;
        bool untilWinning = !teamWinning;
        int lastI = playerIx;
        mm_inflectionIx = -1;
        for (int i = playerIx + dir; dir > 0 ? i < int(players.Length) : i >= 0; i += dir) {
            // swap i with lastI
            auto tmpI = mm_finishedTeamOrder[i];
            if (tmpI != playersTeam) {
                mm_finishedTeamOrder[i] = mm_finishedTeamOrder[lastI];
                mm_finishedTeamOrder[lastI] = tmpI;
                teamsData.ComputePoints(mm_finishedTeamOrder, mm_points, mm_teamTotals);
                bool newWinning = mm_teamTotals[playersTeam] > mm_teamTotals[otherTeam];
                if (newWinning == untilWinning) {
                    // we hit the inflection point at index i
                    mm_inflectionIx = i;
                    break;
                }
            }
            lastI = i;
        }

        // safe indicators test

        bool teamIsBehind = !teamWinning;

        auto localPlayer = players[playerIx];
        if (ta_playerTime is null) @ta_playerTime = WrapPlayerCpInfo(localPlayer);
        else ta_playerTime.UpdateFrom(localPlayer);

        if (mm_inflectionIx < 0) {
            mm_inflectionIx = teamWinning ? nbPlayers - 1 : 0;
            if (mm_inflectionIx == playerIx) mm_inflectionIx = -1;
        }

        if (mm_inflectionIx < 0) {
            // we are either too far behind or too far ahead to lose.
            // e.g., if team order is 1,1,1,2,2,2, then even if a team 1 player DNFs their team can still win
            // alt, no team member on team 2 can win the match for their team by coming first (would be 9 points total)
            DrawBufferTime(99999, teamIsBehind, GetBufferTimeColor(2, teamIsBehind));
        } else {
            auto targetPlayer = players[mm_inflectionIx];
            if (mm_targetTime is null) @mm_targetTime = WrapPlayerCpInfo(targetPlayer);
            else mm_targetTime.UpdateFrom(targetPlayer);

            bool isBehind = ta_playerTime > mm_targetTime;

            auto msDelta = CalcMsDelta(ta_playerTime, isBehind, mm_targetTime);
            auto cpDelta = Math::Abs(ta_playerTime.cpCount - mm_targetTime.cpCount);
            DrawBufferTime(msDelta, isBehind, GetBufferTimeColor(cpDelta, isBehind));
        }

        if (!ctrlPlayerFinished && isPlaying && S_MM_ShowMvpDelta && mvpPlayerIx >= 0 && mvpPlayerIx != playerIx) {
            if (mm_mvpTime is null) @mm_mvpTime = WrapPlayerCpInfo(players[mvpPlayerIx]);
            else mm_mvpTime.UpdateFrom(players[mvpPlayerIx]);

            bool isBehind = ta_playerTime > mm_mvpTime;

            auto msDelta = CalcMsDelta(ta_playerTime, isBehind, mm_mvpTime);
            auto cpDelta = Math::Abs(ta_playerTime.cpCount - mm_mvpTime.cpCount);
            DrawBufferTime(msDelta, isBehind, GetBufferTimeColor(cpDelta, isBehind), true);
        } else {
            @mm_mvpTime = null;
        }

        // buffer measures time you can lose before your change in position causes your team to lose.
        // get predicted team winner -- tells us behind or in front
        // move the player up/down to find where the score inflects.
        // the player immediately above/below us is then the cutoff (should always be someone of another team, since overtaking your own team mate doesn't change score)
        // calc delta between local player and that player
        // after player finished also calc score delta to show in secondary timer (mb MM score, too)
    }


    void Render_KO(bool isPlaying, bool isFinish, bool isEndRound) {
        if (isEndRound) return;
        if (!KoBuffer::IsGameModeCotdKO) return;

        // calc player's position relative to ko position
        // target: either player right before or after ko pos
        // if (koFeedHook is null || theHook is null) return;
        auto theHook = MLFeed::GetRaceData_V3();
        auto koFeedHook = MLFeed::GetKoData();

        if (koFeedHook.RoundNb <= 0) return;
        if (!Setting_SafeIndicatorInNoKO) {
            if (koFeedHook.KOsNumber == 0) return;
        }

        string localUser = KoBuffer::Get_App_CurrPlayground_GameTerminal_GUIPlayerUserName(GetApp());
        uint nPlayers = koFeedHook.PlayersNb;
        uint nKOs = koFeedHook.KOsNumber;
        uint preCutoffRank = nPlayers - nKOs;
        uint postCutoffRank = preCutoffRank + 1;
        uint nbDNFs = 0; // used to track how many DNFs/non-existent players are before the cutoff ranks
        MLFeed::PlayerCpInfo_V2@ preCpInfo = null;
        MLFeed::PlayerCpInfo_V2@ postCpInfo = null;
        MLFeed::PlayerCpInfo_V2@ localPlayer = null;
        auto @sorted = S_UpdateInstantRespawns ? theHook.SortedPlayers_Race_Respawns : theHook.SortedPlayers_Race;
        // todo: if postCpInfo is null it might be because there aren't enough players, so count as 0 progress?

        for (uint i = 0; i < sorted.Length; i++) {
            // uint currRank = i + 1;
            auto player = sorted[i];
            if (player is null) {
                nbDNFs += 1;
                continue; // edge case on changing maps, player leaves, etc
            }
            else if (player.name == localUser) @localPlayer = player;
            auto koPlayer = koFeedHook.GetPlayerState(player.name);
            if (koPlayer.isDNF) nbDNFs += 1;
            else { // we don't want to use a DNFd player so skip them; if one of these conditions would be true now, it would have been true for the prior player, so we don't want to overwrite it either
                auto rank = S_UpdateInstantRespawns ? player.RaceRespawnRank : player.RaceRank;
                if (rank == preCutoffRank + nbDNFs) @preCpInfo = player;
                if (rank == postCutoffRank + nbDNFs) @postCpInfo = player;
            }

            if (localPlayer !is null && postCpInfo !is null) break; // got everything we need
        }

        if (localPlayer is null) return;

        if (ta_playerTime is null) @ta_playerTime = WrapPlayerCpInfo(localPlayer);
        else ta_playerTime.UpdateFrom(localPlayer);

        auto bufferTime = CalcBufferTime_KO(theHook, koFeedHook, preCpInfo, postCpInfo, localPlayer, postCutoffRank, true);
        if (bufferTime.isOut && Setting_ShowOutIndicatorEver) {
            DrawBufferTime(99999, true, GetBufferTimeColor(99, true));
        } else if (bufferTime.isSafe && (Setting_ShowSafeIndicatorEver || (koFeedHook.KOsNumber == 0 && Setting_SafeIndicatorInNoKO))) {
            DrawBufferTime(99999, false, GetBufferTimeColor(99, false));
        } else {
            vec4 bufColor = GetBufferTimeColor(bufferTime.cpDelta, bufferTime.isBehind);
            DrawBufferTime(bufferTime.msDelta, bufferTime.isBehind, bufColor);
        }
    }

    BufferTime@ CalcBufferTime_KO(const MLFeed::HookRaceStatsEventsBase_V2@ theHook, const MLFeed::KoDataProxy@ koFeedHook,
                        MLFeed::PlayerCpInfo_V2@ preCpInfo,
                        MLFeed::PlayerCpInfo_V2@ postCpInfo,
                        MLFeed::PlayerCpInfo_V2@ localPlayer,
                        uint postCutoffRank,
                        bool drawBufferTime = false
    ) {
        if (localPlayer is null) return BufferTime(0, 1, true, false, false, false, false);
        auto localPlayerState = koFeedHook.GetPlayerState(localPlayer.name);

        auto lpRank = S_UpdateInstantRespawns ? localPlayer.RaceRespawnRank : localPlayer.RaceRank;
        bool localPlayerLives = localPlayerState is null || (!localPlayerState.isDNF && localPlayerState.isAlive);
        bool isAlive = localPlayerState is null || localPlayerState.isAlive;
        bool isDNF = localPlayerState !is null && localPlayerState.isDNF;


        if (preCpInfo is null) return BufferTime(99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);

        bool isOut = (int(lpRank) > koFeedHook.PlayersNb - koFeedHook.KOsNumber)
                && preCpInfo.cpCount == int(theHook.CPsToFinish);

        bool postCpAlive = postCpInfo !is null;
        if (postCpAlive) {
            auto playerState = koFeedHook.GetPlayerState(postCpInfo.name);
            if (playerState !is null) {
                postCpAlive = !playerState.isDNF && playerState.isAlive;
            }
        }

        bool isSafe = (int(lpRank) <= koFeedHook.PlayersNb - koFeedHook.KOsNumber)
                && !postCpAlive && localPlayerLives;

        if (isOut && drawBufferTime && Setting_ShowOutIndicatorEver) {
            return BufferTime(99999, 99, true, false, true, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        if (isSafe && drawBufferTime && Setting_ShowSafeIndicatorEver) {
            return BufferTime(99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);
        }


        MLFeed::PlayerCpInfo_V2@ targetCpInfo;
        bool isBehind;

        // ahead of 1st player to be eliminated?
        if (lpRank < postCutoffRank) @targetCpInfo = postCpInfo;
        else @targetCpInfo = preCpInfo; // otherwise, if at risk of elim

        if (targetCpInfo is null) {
            return BufferTime(99999, 99, false, localPlayerLives, !localPlayerLives, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        auto tgRank = S_UpdateInstantRespawns ? targetCpInfo.RaceRespawnRank : targetCpInfo.RaceRank;

        // ranks should never be ==
        isBehind = lpRank > tgRank && (localPlayer.cpCount > 0 || localPlayer.TimeLostToRespawns > 0 || targetCpInfo.cpCount > 0);
        uint cpDelta = Math::Abs(localPlayer.cpCount - targetCpInfo.cpCount);

        int msDelta = CalcMsDelta(WrapPlayerCpInfo(localPlayer), isBehind, WrapPlayerCpInfo(targetCpInfo));
        return BufferTime(msDelta, cpDelta, isBehind, isSafe, isOut, isAlive, isDNF);
    }

    int CalcMsDelta(CPAbstraction@ localPlayer, bool isBehind, CPAbstraction@ targetCpInfo) {
        int msDelta;
        auto currRaceTime = KoBuffer::GetCurrentRaceTime(GetApp());

        auto aheadPlayer = isBehind ? targetCpInfo : localPlayer;
        auto behindPlayer = isBehind ? localPlayer : targetCpInfo;
        int expectedExtraCps = 0;
        if (aheadPlayer.cpCount > behindPlayer.cpCount) {
            int futureTimeLost = 0;
            for (int i = behindPlayer.cpCount; i <= aheadPlayer.cpCount; i++) {
                futureTimeLost += aheadPlayer.tltr[i];
            }
            auto timeSinceCp = currRaceTime - behindPlayer.lastCpTime;
            auto aheadPlayersNextCpDuration =
                aheadPlayer.cpTimes[behindPlayer.cpCount + 1]
                - aheadPlayer.cpTimes[behindPlayer.cpCount];
            expectedExtraCps = Math::Max(timeSinceCp, aheadPlayersNextCpDuration)
                - (S_UpdateInstantRespawns ? futureTimeLost : 0);
            msDelta = behindPlayer.lastCpTime
                - aheadPlayer.cpTimes[behindPlayer.cpCount + 1]
                + expectedExtraCps;
        } else if (aheadPlayer.cpCount < behindPlayer.cpCount) {
            // should never be true
            msDelta = 98765;
            warn("Ahead Player has fewer CPs than Behind Player!");
#if DEV
            NotifyError("Ahead Player has fewer CPs than Behind Player!");
#endif
        } else {
            msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount]
                - (S_UpdateInstantRespawns ? aheadPlayer.tltr[behindPlayer.cpCount] : 0);
        }
        return msDelta;
    }

    class BufferTime {
        // MLFeed::PlayerCpInfo@ localPlayer;
        uint msDelta;
        uint cpDelta;
        bool isBehind;
        bool isSafe;
        bool isOut;
        bool isAlive;
        bool isDNF;
        BufferTime(uint _msDelta, uint _cpDelta, bool _isBehind, bool _isSafe = false, bool _isOut = false, bool _isAlive = true, bool _isDNF = false) {
            msDelta = _msDelta;
            cpDelta = _cpDelta;
            isBehind = _isBehind;
            isSafe = _isSafe;
            isOut = _isOut;
            isAlive = _isAlive;
            isDNF = _isDNF;
        }
    }

    int mediumDisplayFont = nvg::LoadFont("fonts/MontserratMono-Medium.ttf", true, true);
    int mediumItalicDisplayFont = nvg::LoadFont("fonts/MontserratMono-MediumItalic.ttf", true, true);
    int semiBoldDisplayFont = nvg::LoadFont("fonts/MontserratMono-SemiBold.ttf", true, true);
    int semiBoldItalicDisplayFont = nvg::LoadFont("fonts/MontserratMono-SemiBoldItalic.ttf", true, true);
    int boldDisplayFont = nvg::LoadFont("fonts/MontserratMono-Bold.ttf", true, true);
    int boldItalicDisplayFont = nvg::LoadFont("fonts/MontserratMono-BoldItalic.ttf", true, true);

    int oswaldBoldFont = nvg::LoadFont("fonts/OswaldMono-Bold.ttf", true, true);
    int oswaldSemiBoldFont = nvg::LoadFont("fonts/OswaldMono-SemiBold.ttf", true, true);
    int oswaldLightFont = nvg::LoadFont("fonts/OswaldMono-Light.ttf", true, true);
    int oswaldExtraLightFont = nvg::LoadFont("fonts/OswaldMono-ExtraLight.ttf", true, true);
    int oswaldMediumFont = nvg::LoadFont("fonts/OswaldMono-Medium.ttf", true, true);
    int oswaldRegularFont = nvg::LoadFont("fonts/OswaldMono-Regular.ttf", true, true);

    UI::Font@ ui_mediumDisplayFont = null;
    UI::Font@ ui_mediumItalicDisplayFont = null;
    UI::Font@ ui_semiBoldDisplayFont = null;
    UI::Font@ ui_semiBoldItalicDisplayFont = null;
    UI::Font@ ui_boldDisplayFont = null;
    UI::Font@ ui_boldItalicDisplayFont = null;

    UI::Font@ ui_oswaldBoldFont = null;
    UI::Font@ ui_oswaldSemiBoldFont = null;
    UI::Font@ ui_oswaldLightFont = null;
    UI::Font@ ui_oswaldExtraLightFont = null;
    UI::Font@ ui_oswaldMediumFont = null;
    UI::Font@ ui_oswaldRegularFont = null;

    enum FontChoice {
        Montserrat_Medium = 0,
        Montserrat_Medium_Italic,
        Montserrat_SemiBold,
        Montserrat_SemiBold_Italic,
        Montserrat_Bold,
        Montserrat_Bold_Italic,
        Oswald_ExtraLight,
        Oswald_Light,
        Oswald_Regular,
        Oswald_Medium,
        Oswald_SemiBold,
        Oswald_Bold,
    }

    array<int> fontChoiceToFont =
        { mediumDisplayFont
        , mediumItalicDisplayFont
        , semiBoldDisplayFont
        , semiBoldItalicDisplayFont
        , boldDisplayFont
        , boldItalicDisplayFont
        , oswaldExtraLightFont
        , oswaldLightFont
        , oswaldRegularFont
        , oswaldMediumFont
        , oswaldSemiBoldFont
        , oswaldBoldFont
        };

    array<UI::Font@> ui_fontChoiceToFont =
        { ui_mediumDisplayFont
        , ui_mediumItalicDisplayFont
        , ui_semiBoldDisplayFont
        , ui_semiBoldItalicDisplayFont
        , ui_boldDisplayFont
        , ui_boldItalicDisplayFont
        , ui_oswaldExtraLightFont
        , ui_oswaldLightFont
        , ui_oswaldRegularFont
        , ui_oswaldMediumFont
        , ui_oswaldSemiBoldFont
        , ui_oswaldBoldFont
        };

    bool _loadedFonts = false;
    void LoadImGuiFonts() {
        if (_loadedFonts) return;
        _loadedFonts = true;
        startnew(_LoadFonts);
    }

    void _LoadFonts() {
        UI::ShowNotification(Meta::ExecutingPlugin().Name, "Loading fonts for preview. You will notice 12 stutters.", 15000);
        sleep(250);
        @ui_fontChoiceToFont[0] = UI::LoadFont("fonts/MontserratMono-Medium.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[1] = UI::LoadFont("fonts/MontserratMono-MediumItalic.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[2] = UI::LoadFont("fonts/MontserratMono-SemiBold.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[3] = UI::LoadFont("fonts/MontserratMono-SemiBoldItalic.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[4] = UI::LoadFont("fonts/MontserratMono-Bold.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[5] = UI::LoadFont("fonts/MontserratMono-BoldItalic.ttf", 16, 0x002b, 0x003b);
        sleep(500);

        @ui_fontChoiceToFont[6] = UI::LoadFont("fonts/OswaldMono-Bold.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[7] = UI::LoadFont("fonts/OswaldMono-SemiBold.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[8] = UI::LoadFont("fonts/OswaldMono-Light.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[9] = UI::LoadFont("fonts/OswaldMono-ExtraLight.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[10] = UI::LoadFont("fonts/OswaldMono-Medium.ttf", 16, 0x002b, 0x003b);
        sleep(500);
        @ui_fontChoiceToFont[11] = UI::LoadFont("fonts/OswaldMono-Regular.ttf", 16, 0x002b, 0x003b);
    }

    string GetPlusMinusFor(bool isBehind) {
        return (isBehind ^^ Setting_SwapPlusMinus) ? "-" : "+";
    }

    void DrawReferenceFinalTime(int finalTime, const vec4 &in bufColor, bool isSecondary = false) {
        auto font = fontChoiceToFont[uint(Setting_Font)];
        DrawBufferTime_Inner(Time::Format(Math::Max(finalTime, 0)), bufColor, font, isSecondary);
    }

    void ShowMvpDeltaPreview() {
        int d = Time::Now / 250 % 11 - 5;
        bool isMVP = d > 0;
        // if (d == 0) isMVP = Math::Rand(0, 2) == 1;
        DrawMvpPointsDelta(Math::Abs(d), isMVP);
    }

    void DrawMvpPointsDelta(int delta, bool isBehind) {
        if (!S_MM_ShowMvpPointsDelta && !S_ShowMvpDelta_Preview) return;
        auto font = fontChoiceToFont[uint(Setting_Font)];
        DrawBufferTime_Inner((isBehind ? "-" : "+") + tostring(delta), GetBufferTimeColor(2, isBehind), font, true);
    }

    void DrawBufferTime(int msDelta, bool isBehind, const vec4 &in bufColor, bool isSecondary = false) {
        auto font = fontChoiceToFont[uint(Setting_Font)];
        msDelta = Math::Abs(msDelta);
        nvg::Reset();
        string toDraw = GetPlusMinusFor(isBehind) + MsToSeconds(msDelta);
        DrawBufferTime_Inner(toDraw, bufColor, font, isSecondary);
    }

    void DrawBufferTime_Inner(const string &in toDraw, const vec4 &in bufColor, int font, bool isSecondary = false) {
        auto screen = vec2(Draw::GetWidth(), Draw::GetHeight());
        vec2 pos = (screen * Setting_BufferDisplayPosition / vec2(100, 100));// - (size / 2);
        float fontSize = Setting_BufferFontSize;
        float sw = Setting_StrokeWidth;
        if (isSecondary) {
            pos = CalcBufferTimeSecondaryPos(pos, fontSize);
            fontSize *= S_SecondaryTimerScale;
            sw *= Math::Sqrt(S_SecondaryTimerScale);
        }

        nvg::FontFace(font);
        nvg::FontSize(fontSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        auto sizeWPad = nvg::TextBounds(toDraw.SubStr(0, toDraw.Length - 3) + "000") + vec2(20, 10);

        if (Setting_DrawBufferTimeBG) {
            nvg::BeginPath();
            nvg::FillColor(Setting_BufferTimeBGColor);
            nvg::Rect(pos - sizeWPad / 2, sizeWPad);
            nvg::Fill();
            nvg::ClosePath();
        }

        // "stroke"
        if (Setting_EnableStroke) {
            float nCopies = 32; // this does not seem to be expensive
            nvg::FillColor(vec4(0,0,0, bufColor.w * Setting_StrokeAlpha));
            for (float i = 0; i < nCopies; i++) {
                float angle = TAU * float(i) / nCopies;
                vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
                nvg::Text(pos + offs, toDraw);
            }
        }

        nvg::FillColor(bufColor);
        nvg::Text(pos, toDraw);
    }

    vec2 CalcBufferTimeSecondaryPos(vec2 pos, float fontSize) {
        vec2 offs = vec2(0, fontSize * (1. + S_SecondaryTimerScale) / 2. + 10 - .25) * (Setting_BufferDisplayPosition.y >= 50. ? 1 : -1);
        return pos + offs;
    }


    vec4 GetBufferTimeColor(uint cpDelta, bool isBehind) {
        return cpDelta < 2
            ? (isBehind ? Col_BehindDefinite : Col_AheadDefinite)
            : (isBehind ? Col_FarBehind : Col_FarAhead);
    }

    string get_MenuShortcutStr() {
        if (Setting_ShortcutKeyEnabled)
            return tostring(Setting_ShortcutKey);
        return "";
    }

    UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
        if (Setting_ShortcutKeyEnabled && down && key == Setting_ShortcutKey) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
            UI::ShowNotification(Meta::ExecutingPlugin().Name, "Toggled " + Meta::ExecutingPlugin().Name + " visibility. (Currently visible? " + (g_koBufferUIVisible ? Icons::Check : Icons::Times) + ")");
            return UI::InputBlocking::Block;
        }
        return UI::InputBlocking::DoNothing;
    }

    const uint64 tsAtLoad = Time::Stamp;
    // this shows the final time on race completion of the player
    void DrawFinalTime() {
        string toDraw;
        string toDraw2;
        if (S_ShowFinalTime_Preview) {
            uint64 ts = ((tsAtLoad % 86400) % 3600) * 1000 + (Time::Now % 100000);
            ts -= (ts % 1337);  // will update every 1.337 seconds with a new time
            if (ta_playerTime !is null && ta_playerTime.lastCpTime > 0)
                ts = uint(ta_playerTime.lastCpTime);
            toDraw = Time::Format(ts, true, true);
        } else {
            if (S_FT_OnlyWhenInterfaceHidden && UI::IsGameUIVisible()) return;
            if (ta_playerTime is null) return;
            uint finalTime = uint(ta_playerTime.lastCpTime);
            uint theoreticalTime = uint(ta_playerTime.LastTheoreticalCpTime);
            toDraw = Time::Format(finalTime);
            if (finalTime != theoreticalTime) {
                toDraw2 = Time::Format(theoreticalTime) + "; +" + ta_playerTime.NbRespawns;
            }
        }

        nvg::Reset();
        auto screen = vec2(Draw::GetWidth(), Draw::GetHeight());
        vec2 pos = (screen * S_FT_DisplayPosition / vec2(100, 100));
        float fontSize = S_FT_FontSize;
        float sw = S_FT_StrokeWidth;

        nvg::FontFace(fontChoiceToFont[S_FT_Font]);
        nvg::FontSize(fontSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);

        for (uint i = 0; i < 2; i++) {
            if (i == 1) {
                if (!S_FT_ShowNoRespawnTime) continue;
                if (toDraw2.Length == 0) continue;
                // mod settings for theoretical time
                pos.y += fontSize * 0.75;
                fontSize /= 2.;
                sw *= 0.67;
                toDraw = toDraw2;
                nvg::FontSize(fontSize);
            }

            // "stroke"
            if (S_FT_EnableStroke) {
                float nCopies = 32; // this does not seem to be expensive
                nvg::FillColor(Col_FT_Stroke);
                for (float j = 0; j < nCopies; j++) {
                    float angle = TAU * float(j) / nCopies;
                    if (S_FT_ReplaceStrokeWithShadow)
                        angle = TAU * S_FT_ShadowAngle / 360.;
                    vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
                    nvg::Text(pos + offs, toDraw);
                    if (S_FT_ReplaceStrokeWithShadow)
                        break;
                }
            }

            nvg::FillColor(Col_FT_Main);
            nvg::Text(pos, toDraw);
        }
    }

    /* DEBUG WINDOW: SHOW ALL */

    void RenderInterface() {
        if (!(S_ShowAllInfoDebug)) return;
        if (UI::Begin("KO Buffer -- All Players", S_ShowAllInfoDebug)) {

            auto theHook = MLFeed::GetRaceData_V2();
            auto koFeedHook = MLFeed::GetKoData();

            int nPlayers = Math::Max(0, koFeedHook.PlayersNb);
            int nKOs = Math::Max(0, koFeedHook.KOsNumber);
            uint preCutoffRank = Math::Max(1, nPlayers - nKOs);
            uint postCutoffRank = preCutoffRank + 1;
            MLFeed::PlayerCpInfo_V2@ preCpInfo = null;
            MLFeed::PlayerCpInfo_V2@ postCpInfo = null;
            auto @sorted = theHook.SortedPlayers_Race_Respawns;
            for (uint i = 0; i < sorted.Length; i++) {
                // uint currRank = i + 1;
                auto player = sorted[i];
                if (player is null) continue; // edge case on changing maps and things
                if (player.RaceRespawnRank == preCutoffRank) @preCpInfo = player;
                if (player.RaceRespawnRank == postCutoffRank) @postCpInfo = player;
            }

            UI::Text("nPlayers: " + nPlayers);
            UI::Text("nKOs: " + nKOs);
            UI::Text("preCutoffRank: " + preCutoffRank);
            UI::Text("postCutoffRank: " + postCutoffRank);
            UI::Text("preCpInfo is null: " + (preCpInfo is null ? "yes" : "no"));
            UI::Text("postCpInfo is null: " + (postCpInfo is null ? "yes" : "no"));

            UI::Text("");
            UI::TextWrapped("""\$6dfΔt (s):\$z the delta between the player's time and that of the player just above or below the cutoff, depending.
\$6dfCP Δ:\$z the difference in the number of CPs between the player and the one just above or below the cutoff.
\$6dfBehind?:\$z whether the player is at risk of elimination.
\$6dfSafe?:\$z whether the player cannot be eliminated provided that they finish.
\$6dfOut?:\$z whether the player is destined to be eliminated.
\$6dfAlive?:\$z false after the player has been eliminated.
\$6dfDNF?:\$z whether the player DNF (only true while alive).
""");
            UI::Text("");

            if (UI::BeginTable("kobuffer-all", 9, UI::TableFlags::SizingStretchProp)) {
                UI::TableSetupColumn("##rank", UI::TableColumnFlags::WidthFixed, 25.);
                UI::TableSetupColumn("Name");
                UI::TableSetupColumn("Δt (ms)");
                UI::TableSetupColumn("CP Δ");
                UI::TableSetupColumn("Behind?");
                UI::TableSetupColumn("Safe?");
                UI::TableSetupColumn("Out?");
                UI::TableSetupColumn("Alive?");
                UI::TableSetupColumn("DNF?");
                UI::TableHeadersRow();

                UI::ListClipper clip(sorted.Length);

                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        auto player = sorted[i];
                        auto bt = CalcBufferTime_KO(theHook, koFeedHook, preCpInfo, postCpInfo, player, postCutoffRank);
                        auto pm = GetPlusMinusFor(bt.isBehind);

                        // columns
                        UI::TableNextRow();

                        UI::TableNextColumn();
                        UI::Text("" + player.RaceRespawnRank);

                        UI::TableNextColumn();
                        UI::Text("" + player.name);

                        UI::TableNextColumn();
                        auto col = GetBufferTimeColor(bt.cpDelta, bt.isBehind);
                        UI::PushStyleColor(UI::Col::Text, col);
                        UI::Text(pm + bt.msDelta);

                        UI::TableNextColumn();
                        UI::Text(pm + bt.cpDelta);
                        UI::PopStyleColor();

                        UI::TableNextColumn();
                        ColoredBoleanIconText(bt.isBehind, false);

                        UI::TableNextColumn();
                        ColoredBoleanIconText(bt.isSafe, true);

                        UI::TableNextColumn();
                        ColoredBoleanIconText(bt.isOut, false);

                        UI::TableNextColumn();
                        ColoredBoleanIconText(bt.isAlive, true);

                        UI::TableNextColumn();
                        ColoredBoleanIconText(bt.isDNF, false);
                    }
                }

                UI::EndTable();
            }
        }
        UI::End();
    }

    void ColoredBoleanIconText(bool v, bool trueIsGood) {
        auto col = (!(v ^^ trueIsGood)) ? Col_FarAhead : Col_FarBehind;
        UI::PushStyleColor(UI::Col::Text, col);
        UI::Text(v ? Icons::Check : Icons::Times);
        UI::PopStyleColor();
    }
}


string[]@ IntsToStrs(const int[] &in ints) {
    string[] strs;
    for (uint i = 0; i < ints.Length; i++) {
        strs.InsertLast(tostring(ints[i]));
    }
    return strs;
}


void dev_trace(const string &in msg) {
#if DEV
    trace(msg);
#endif
}
