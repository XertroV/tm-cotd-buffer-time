const float TAU = 6.283185307179586;

namespace KoBuffer {
/* bugs:
- when at 0, no behind shows up even if it should:
  d = RaceTime - ahead.lastCP
  nb: racetime here is sorta the curr pos of the ahead car

*/
    void Main() {
        dev_trace("KoBuffer::Main");
        startnew(InitCoro);
    }

    void InitCoro() {
        dev_trace("KoBuffer::InitCoro");
        startnew(MainCoro);
        if (Setting_BufferFontSize < 0.1) {
            Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;
        }
    }

    void MainCoro() {
        dev_trace("KoBuffer::MainCoro");
        while (true) {
            yield();
            CheckGMChange();
        }
    }

    string lastGM = "nonexistent init";
    void CheckGMChange() {
        if (CurrentGameMode != lastGM) {
            lastGM = CurrentGameMode;
            dev_trace("Set game mode: " + lastGM);
            // if (IsGameModeCotdKO) {
            // }
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
            || lastGM == "TM_Campaign_Local"
            ;
    }

    bool get_IsGameModeCotdQuali() {
        return lastGM == "TM_TimeAttackDaily_Online";
    }

    CSmPlayer@ get_App_CurrPlayground_GameTerminal_GUIPlayer() {
        auto cp = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        if (cp is null || cp.GameTerminals.Length < 1) return null;
        auto GameTerminal = cp.GameTerminals[0];
        if (GameTerminal is null) return null;
        return cast<CSmPlayer>(GameTerminal.GUIPlayer);
    }

    string get_App_CurrPlayground_GameTerminal_GUIPlayerUserName() {
        auto GUIPlayer = App_CurrPlayground_GameTerminal_GUIPlayer;
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

    CSmScriptPlayer@ get_GUIPlayer_ScriptAPI() {
        auto GUIPlayer = App_CurrPlayground_GameTerminal_GUIPlayer;
        if (GUIPlayer is null) return null;
        return cast<CSmScriptPlayer>(GUIPlayer.ScriptAPI);
    }

    CSmPlayer@ get_App_CurrPlayground_GameTerminal_ControlledPlayer() {
        auto cp = cast<CSmArenaClient>(GetApp().CurrentPlayground);
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

    // a hacky way to tell if the interface is hidden
    bool IsInterfaceHidden(CGameCtnApp@ app) {
        try {
            return Get_ControlledPlayer_ScriptAPI(app).CurrentRaceTime != GetCurrentRaceTime(app);
        } catch {
            return false;
        }
    }

    CGamePlaygroundUIConfig::EUISequence GetUiSequence(CGameCtnApp@ app) {
        try {
            return app.Network.ClientManiaAppPlayground.UI.UISequence;
        } catch {
            return CGamePlaygroundUIConfig::EUISequence::None;
        }
    }
}

namespace KoBufferUI {

    // const string menuIcon = Icons::ArrowsH;
    const string menuIcon = " Δt";

    // int bufferDisplayFont = nvg::LoadFont("DroidSans.ttf", true, true);

    void RenderMenu() {
        if (UI::MenuItem("\\$faa\\$s" + menuIcon + "\\$z " + Meta::ExecutingPlugin().Name, MenuShortcutStr, g_koBufferUIVisible)) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
    }

    void RenderMenuMain() {
        if (!g_koBufferUIVisible || S_HideIncrediblyUsefulMenuBarItem) return;
        bool isShowing = false
            || (S_ShowBufferTimeInKO && KoBuffer::IsGameModeCotdKO)
            || (S_ShowBufferTimeInTA && KoBuffer::IsGameModeTA)
            ;
        if (!isShowing) return;
        string shortcut = Setting_ShortcutKeyEnabled ? "\\$bbb (" + tostring(Setting_ShortcutKey) + ")" : "";
        if (UI::BeginMenu("\\$faa\\$s" + menuIcon + "\\$z " + Meta::ExecutingPlugin().Name + shortcut)) {
            if (KoBuffer::IsGameModeCotdKO) RenderKoMenuMainInner();
            else if (KoBuffer::IsGameModeTA) RenderTaMenuMainInner();
            else RenderUnknownMenuMainInner();
            UI::EndMenu();
        }
    }

    void RenderKoMenuMainInner() {
        UI::Text("\\$bbb   KO / COTD Options");
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

    void RenderTaMenuMainInner() {
        UI::Text("\\$bbb  Time Attack / Campaign Options");
        if (UI::BeginMenu("Disable Buffer Time during TA")) {
                if (KoBuffer::IsGameModeCotdQuali) {
                    bool disableCotdQuali = UI::MenuItem("Disable for COTD Quali");
                    AddSimpleTooltip("You will need to re-enable it for COTD Quali in 'TA / Campaign' settings.");
                    if (disableCotdQuali) S_TA_ShowDuringCotdQuali = false;
                }
                bool disableNow = UI::MenuItem("Disable Now");
                AddSimpleTooltip("You will need to re-enable it for TA in 'Global' settings.");
                if (disableNow) S_ShowBufferTimeInTA = false;
            UI::EndMenu();
        }
        UI::Separator();
        UI::Text("\\$bbb  Current Ghosts:");
        string choiceLabel = FormatNameAndTime(S_TA_GhostName, S_TA_GhostTime);
        if (UI::BeginMenu("Ghost Choice:")) {
            bool choiceBestGhost = S_TA_GhostChoice == GhostChoice::BestGhost;
            if (UI::MenuItem("Best Ghost", "", choiceBestGhost)) {
                S_TA_GhostChoice = GhostChoice::BestGhost;
            }
            auto GD = MLFeed::GetGhostData();
            bool listedPriorityGhost = false;
            // string localPlayerName = KoBuffer::Get_GameTerminal_ControlledPlayer_UserName(GetApp());
            dictionary seenGhosts;
            string key;
            for (uint i = 0; i < GD.Ghosts.Length; i++) {
                auto item = GD.Ghosts[i];
                key = item.Nickname + item.Result_Time;
                if (seenGhosts.Exists(key)) continue;
                seenGhosts[key] = true;
                bool selected = item.Result_Time == S_TA_GhostTime && item.Nickname == S_TA_GhostName;
                // if (item.Nickname == localPlayerName || item.Nickname.EndsWith("Personal best"))
                //     continue;  // we handle player ghosts separately
                if (UI::MenuItem(GhostInfoLabel(item), "", selected && !choiceBestGhost)) {
                    S_TA_GhostChoice = GhostChoice::NamedGhost;
                    S_TA_GhostName = item.Nickname;
                    S_TA_GhostTime = item.Result_Time;
                }
                listedPriorityGhost = listedPriorityGhost || selected;
            }
            if (!listedPriorityGhost) {
                UI::MenuItem(choiceLabel, "", !choiceBestGhost, false);
            }
            UI::EndMenu();
        }
        UI::Text("\\$bbb  Priority: " + WrappedTimesLabel(priorityGhost));
        UI::Text("\\$bbb  Secondary: " + WrappedTimesLabel(secondaryGhost));
        UI::Text("\\$bbb  Tertiary: " + WrappedTimesLabel(tertiaryGhost));

        UI::Separator();

        if (UI::MenuItem("Show Vs. Ghost?", "", S_TA_VsBestGhost))
            S_TA_VsBestGhost = !S_TA_VsBestGhost;

        if (UI::MenuItem("Show Vs. Best Time?", "", S_TA_VsBestRecentTime))
            S_TA_VsBestRecentTime = !S_TA_VsBestRecentTime;

        if (UI::MenuItem("Show Vs. PB?", "", S_TA_VsPB))
            S_TA_VsPB = !S_TA_VsPB;

        if (UI::MenuItem("Show Two Buf. Times?", "", S_TA_ShowTwoBufferTimes))
            S_TA_ShowTwoBufferTimes = !S_TA_ShowTwoBufferTimes;

        UI::Separator();

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
        // UI::Text("\\$bbb   Currently prioritizing: " + tostring(S_TA_PrioritizedType));
        // auto otherPriorityType = TaBufferTimeType((uint(S_TA_PrioritizedType) + 1 ) % 2);
        // if (UI::MenuItem("Change priority to " + tostring(otherPriorityType)))
        //     S_TA_PrioritizedType = otherPriorityType;
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
        return ((ghost is null) ? "null" : (ghost.Nickname + " ("+Time::Format(ghost.Result_Time)+")"));
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
    void Render() {
        if (Setting_ShowPreview) {
            ShowPreview();
            if (Setting_ShowSecondaryPreview)
                ShowPreview(true);
            return;
        }
        currSeq = KoBuffer::GetUiSequence(GetApp());
        bool skipSequence =
            currSeq != CGamePlaygroundUIConfig::EUISequence::Playing
            && currSeq != CGamePlaygroundUIConfig::EUISequence::Finish
            && currSeq != CGamePlaygroundUIConfig::EUISequence::EndRound;
        if (!g_koBufferUIVisible || skipSequence
            || (S_ShowOnlyWhenInterfaceHidden && !KoBuffer::IsInterfaceHidden(GetApp()))
        ) {
            Reset_TA();
            return;
        }

        if (S_ShowBufferTimeInKO && KoBuffer::IsGameModeCotdKO)
            Render_KO();
        else if (S_ShowBufferTimeInTA && KoBuffer::IsGameModeTA)
            Render_TA();
    }

    WrapPlayerCpInfo@ ta_playerTime;
    WrapBestTimes@ ta_bestTime;
    WrapGhostInfo@ ta_bestGhost;
    WrapGhostInfo@ ta_pbGhost;
    WrappedTimes@ priorityGhost;
    WrappedTimes@ secondaryGhost;
    WrappedTimes@ tertiaryGhost;

    void Reset_TA() {
        @ta_playerTime = null;
        @ta_bestTime = null;
        @ta_bestGhost = null;
        @ta_pbGhost = null;
        @priorityGhost = null;
        @secondaryGhost = null;
        @tertiaryGhost = null;
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

    // show buffer in TA against personal best
    void Render_TA() {
        auto crt = KoBuffer::GetCurrentRaceTime(GetApp());

        auto ghostData = MLFeed::GetGhostData();
        if (ghostData.NbGhosts == 0) return; // we need a ghost to get times from
        auto raceData = MLFeed::GetRaceData();
        auto playerName = KoBuffer::Get_GameTerminal_Player_UserName(GetApp());
        auto physicalPlayersName = KoBuffer::Get_GameTerminal_ControlledPlayer_UserName(GetApp());
        auto isSpectating = playerName != physicalPlayersName;
        if (S_TA_HideWhenSpectating && isSpectating) return;
        // trace(tostring(isSpectating));
        auto localPlayer = raceData.GetPlayer(playerName);
        if (localPlayer is null) return;

        if (!S_TA_VsBestGhost && !S_TA_VsBestRecentTime && !S_TA_VsPB) return;


        bool isUiSeqPlaying = currSeq == CGamePlaygroundUIConfig::EUISequence::Playing;
        bool updateGhosts = isUiSeqPlaying;
        const MLFeed::GhostInfo@ chosenGhost = null;
        const MLFeed::GhostInfo@ pbGhost = null;
        bool updateBestGhostNotChosen = S_TA_GhostChoice == GhostChoice::BestGhost;

        if (updateGhosts) {
            for (uint i = 0; i < ghostData.NbGhosts; i++) {
                auto g = ghostData.Ghosts[i];
                bool nameMatches = g.Nickname == playerName;
                bool namePb = g.Nickname.EndsWith("Personal best");

                // pb ghost
                bool checkGhostForPb = !isSpectating && S_TA_VsPB && (nameMatches || namePb);
                // look for best pb ghost
                if (checkGhostForPb && (pbGhost is null || (pbGhost.Result_Time > g.Result_Time))) {
                    @pbGhost = g;
                }

                // chosen ghost
                if (!nameMatches && !namePb && S_TA_VsBestGhost) {
                    if (updateBestGhostNotChosen && (chosenGhost is null || chosenGhost.Result_Time > g.Result_Time))
                        @chosenGhost = g;
                    else if (chosenGhost is null && g.Nickname == S_TA_GhostName && g.Result_Time == S_TA_GhostTime)
                        @chosenGhost = g;
                }
            }
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

        if (S_TA_VsBestRecentTime) {
            if (ta_bestTime is null) @ta_bestTime = WrapBestTimes(playerName, MLFeed::GetPlayersBestTimes(playerName), crt);
            else ta_bestTime.UpdateFrom(playerName, MLFeed::GetPlayersBestTimes(playerName), crt);
        } else {
            @ta_bestTime = null;
        }

        if (S_TA_VsBestGhost) {
            if (ta_bestGhost is null) @ta_bestGhost = WrapGhostInfo(chosenGhost, crt);
            else ta_bestGhost.UpdateFrom(chosenGhost, crt);
        } else {
            @ta_bestGhost = null;
        }

        if (S_TA_VsPB && !isSpectating) {
            if (ta_pbGhost is null) @ta_pbGhost = WrapGhostInfo(pbGhost, crt);
            else ta_pbGhost.UpdateFrom(pbGhost, crt);
        } else {
            @ta_pbGhost = null;
        }

        @priorityGhost = SelectBasedOnType(S_TA_Priority1Type, ta_bestGhost, ta_bestTime, ta_pbGhost);
        @secondaryGhost = SelectBasedOnType(S_TA_Priority2Type, ta_bestGhost, ta_bestTime, ta_pbGhost);
        @tertiaryGhost = SelectBasedOnType(S_TA_Priority3Type, ta_bestGhost, ta_bestTime, ta_pbGhost);

        if (priorityGhost is null || priorityGhost.IsEmpty) {
            if (secondaryGhost is null || secondaryGhost.IsEmpty) {
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

        bool showTwoTimes = S_TA_ShowTwoBufferTimes && secondaryGhost !is null && priorityGhost != secondaryGhost && not secondaryGhost.IsEmpty;

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

    WrappedTimes@ SelectBasedOnType(TaBufferTimeType type, WrappedTimes@ ghost, WrappedTimes@ bestPlayerTimes, WrappedTimes@ pbGhost) {
        if (type == TaBufferTimeType::None) return null;
        if (type == TaBufferTimeType::AgainstGhost) return ghost;
        if (type == TaBufferTimeType::YourBestTime) return bestPlayerTimes;
        if (type == TaBufferTimeType::YourPB) return pbGhost;
        if (type == TaBufferTimeType::BestTimeOrPB) return (pbGhost !is null && pbGhost < bestPlayerTimes) ? pbGhost : bestPlayerTimes;
        throw("SelectBasedOnType invalid type");
        return null;
    }

    void Render_KO() {
        if (!KoBuffer::IsGameModeCotdKO) return; GetApp(); // review helper

        // calc player's position relative to ko position
        // target: either player right before or after ko pos
        // if (koFeedHook is null || theHook is null) return;
        auto theHook = MLFeed::GetRaceData();
        auto koFeedHook = MLFeed::GetKoData();

        if (!Setting_SafeIndicatorInNoKO) {
            // if (koFeedHook.RoundNb == 0) return;
            if (koFeedHook.KOsNumber == 0) return;
        }

        string localUser = KoBuffer::App_CurrPlayground_GameTerminal_GUIPlayerUserName; GetApp(); // review helper
        uint nPlayers = koFeedHook.PlayersNb;
        uint nKOs = koFeedHook.KOsNumber;
        uint preCutoffRank = nPlayers - nKOs;
        uint postCutoffRank = preCutoffRank + 1;
        uint nbDNFs = 0; // used to track how many DNFs/non-existent players are before the cutoff ranks
        MLFeed::PlayerCpInfo@ preCpInfo = null;
        MLFeed::PlayerCpInfo@ postCpInfo = null;
        MLFeed::PlayerCpInfo@ localPlayer = null;
        auto @sorted = theHook.SortedPlayers_Race;
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
                if (player.raceRank == preCutoffRank + nbDNFs) @preCpInfo = player;
                if (player.raceRank == postCutoffRank + nbDNFs) @postCpInfo = player;
            }

            if (localPlayer !is null && postCpInfo !is null) break; // got everything we need
        }

        if (localPlayer is null) return;

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

    BufferTime@ CalcBufferTime_KO(const MLFeed::RaceDataProxy@ theHook, const MLFeed::KoDataProxy@ koFeedHook,
                        MLFeed::PlayerCpInfo@ preCpInfo, MLFeed::PlayerCpInfo@ postCpInfo,
                        MLFeed::PlayerCpInfo@ localPlayer,
                        uint postCutoffRank,
                        bool drawBufferTime = false
    ) {
        if (localPlayer is null) return BufferTime(0, 1, true, false, false, false, false);
        auto localPlayerState = koFeedHook.GetPlayerState(localPlayer.name);

        bool localPlayerLives = localPlayerState is null || (!localPlayerState.isDNF && localPlayerState.isAlive);
        bool isAlive = localPlayerState is null || localPlayerState.isAlive;
        bool isDNF = localPlayerState !is null && localPlayerState.isDNF;


        if (preCpInfo is null) return BufferTime(99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);

        bool isOut = (int(localPlayer.raceRank) > koFeedHook.PlayersNb - koFeedHook.KOsNumber)
                && preCpInfo.cpCount == int(theHook.CPsToFinish);

        bool postCpAlive = postCpInfo !is null;
        if (postCpAlive) {
            auto playerState = koFeedHook.GetPlayerState(postCpInfo.name);
            if (playerState !is null) {
                postCpAlive = !playerState.isDNF && playerState.isAlive;
            }
        }

        bool isSafe = (int(localPlayer.raceRank) <= koFeedHook.PlayersNb - koFeedHook.KOsNumber)
                && !postCpAlive && localPlayerLives;

        if (isOut && drawBufferTime && Setting_ShowOutIndicatorEver) {
            return BufferTime(99999, 99, true, false, true, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        if (isSafe && drawBufferTime && Setting_ShowSafeIndicatorEver) {
            return BufferTime(99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);
        }


        MLFeed::PlayerCpInfo@ targetCpInfo;
        bool isBehind;

        // ahead of 1st player to be eliminated?
        if (localPlayer.raceRank < postCutoffRank) @targetCpInfo = postCpInfo;
        else @targetCpInfo = preCpInfo; // otherwise, if at risk of elim

        if (targetCpInfo is null) {
            return BufferTime(99999, 99, false, localPlayerLives, !localPlayerLives, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        isBehind = localPlayer.raceRank > targetCpInfo.raceRank && targetCpInfo.cpCount > 0; // ranks should never be ==
        uint cpDelta = Math::Abs(localPlayer.cpCount - targetCpInfo.cpCount);

        int msDelta = CalcMsDelta(WrapPlayerCpInfo(localPlayer), isBehind, WrapPlayerCpInfo(targetCpInfo));
        return BufferTime(msDelta, cpDelta, isBehind, isSafe, isOut, isAlive, isDNF);
    }

    int CalcMsDelta(CPAbstraction@ localPlayer, bool isBehind, CPAbstraction@ targetCpInfo) {
        int msDelta;
        auto currRaceTime = KoBuffer::GetCurrentRaceTime(GetApp());

        auto aheadPlayer = isBehind ? targetCpInfo : localPlayer;
        auto behindPlayer = isBehind ? localPlayer : targetCpInfo;
        uint expectedExtraCps = 0;
        // PlayerCpInfo includes zeroth cp time, but GhostInfo does not.
        // is the zeroth cp in aheadPlayer's cp times? (i.e.: cpTimes[0] == 0)?
        // if not, we need to offset access to `aheadPlayer.cpTimes` by -1 (i.e., cpTimes[2 -1] = 2nd CP time);
        // we only use behindPlayer.lastCpTime, so don't need an offset for that.
        int apOffs = (aheadPlayer.cpTimes.Length == 0 || aheadPlayer.cpTimes[0] > 0) ? -1 : 0;
        if (aheadPlayer.cpCount > behindPlayer.cpCount) {
            expectedExtraCps = Math::Max(currRaceTime - behindPlayer.lastCpTime, aheadPlayer.cpTimes[behindPlayer.cpCount + 1 + apOffs] - aheadPlayer.cpTimes[behindPlayer.cpCount + apOffs]);
            msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount + 1 + apOffs] + expectedExtraCps;
        } else if (aheadPlayer.cpCount < behindPlayer.cpCount) {
            // should never be true
            msDelta = 98765;
            warn("Ahead Player has fewer CPs than Behind Player!");
#if DEV
            NotifyError("Ahead Player has fewer CPs than Behind Player!");
#endif
        } else {
            msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount + apOffs];
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

    UI::Font@ ui_mediumDisplayFont = UI::LoadFont("fonts/MontserratMono-Medium.ttf");
    UI::Font@ ui_mediumItalicDisplayFont = UI::LoadFont("fonts/MontserratMono-MediumItalic.ttf");
    UI::Font@ ui_semiBoldDisplayFont = UI::LoadFont("fonts/MontserratMono-SemiBold.ttf");
    UI::Font@ ui_semiBoldItalicDisplayFont = UI::LoadFont("fonts/MontserratMono-SemiBoldItalic.ttf");
    UI::Font@ ui_boldDisplayFont = UI::LoadFont("fonts/MontserratMono-Bold.ttf");
    UI::Font@ ui_boldItalicDisplayFont = UI::LoadFont("fonts/MontserratMono-BoldItalic.ttf");

    UI::Font@ ui_oswaldBoldFont = UI::LoadFont("fonts/OswaldMono-Bold.ttf");
    UI::Font@ ui_oswaldSemiBoldFont = UI::LoadFont("fonts/OswaldMono-SemiBold.ttf");
    UI::Font@ ui_oswaldLightFont = UI::LoadFont("fonts/OswaldMono-Light.ttf");
    UI::Font@ ui_oswaldExtraLightFont = UI::LoadFont("fonts/OswaldMono-ExtraLight.ttf");
    UI::Font@ ui_oswaldMediumFont = UI::LoadFont("fonts/OswaldMono-Medium.ttf");
    UI::Font@ ui_oswaldRegularFont = UI::LoadFont("fonts/OswaldMono-Regular.ttf");


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


    string GetPlusMinusFor(bool isBehind) {
        return (isBehind ^^ Setting_SwapPlusMinus) ? "-" : "+";
    }

    void DrawBufferTime(int msDelta, bool isBehind, vec4 bufColor, bool isSecondary = false) {
        msDelta = Math::Abs(msDelta);
        nvg::Reset();
        string toDraw = GetPlusMinusFor(isBehind) + MsToSeconds(msDelta);
        auto screen = vec2(Draw::GetWidth(), Draw::GetHeight());
        vec2 pos = (screen * Setting_BufferDisplayPosition / vec2(100, 100));// - (size / 2);
        float fontSize = Setting_BufferFontSize;
        float sw = Setting_StrokeWidth;
        if (isSecondary) {
            pos = CalcBufferTimeSecondaryPos(pos, fontSize);
            fontSize *= S_SecondaryTimerScale;
            sw *= Math::Sqrt(S_SecondaryTimerScale);
        }

        nvg::FontFace(fontChoiceToFont[uint(Setting_Font)]);
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

    /* DEBUG WINDOW: SHOW ALL */

    void RenderInterface() {
        if (!(S_ShowAllInfoDebug)) return;
        if (UI::Begin("KO Buffer -- All Players", S_ShowAllInfoDebug)) {

            auto theHook = MLFeed::GetRaceData();
            auto koFeedHook = MLFeed::GetKoData();

            int nPlayers = Math::Max(0, koFeedHook.PlayersNb);
            int nKOs = Math::Max(0, koFeedHook.KOsNumber);
            uint preCutoffRank = Math::Max(1, nPlayers - nKOs);
            uint postCutoffRank = preCutoffRank + 1;
            MLFeed::PlayerCpInfo@ preCpInfo = null;
            MLFeed::PlayerCpInfo@ postCpInfo = null;
            auto @sorted = theHook.SortedPlayers_Race;
            for (uint i = 0; i < sorted.Length; i++) {
                // uint currRank = i + 1;
                auto player = sorted[i];
                if (player is null) continue; // edge case on changing maps and things
                if (player.raceRank == preCutoffRank) @preCpInfo = player;
                if (player.raceRank == postCutoffRank) @postCpInfo = player;
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

                        UI::TableNextColumn();
                        UI::Text("" + player.raceRank);

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

void dev_trace(const string &in msg) {
#if DEV
    trace(msg);
#endif
}
