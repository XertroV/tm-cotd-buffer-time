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
        if (KoBufferUI::Setting_BufferFontSize < 0.1) {
            KoBufferUI::Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;
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
            || lastGM == "TM_TimeAttackDaily_Online"
            || lastGM == "TM_TimeAttack"
            || lastGM == "TM_TimeAttack_Debug"
            || lastGM == "TM_Campaign_Local"
            ;
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

    CSmScriptPlayer@ get_ControlledPlayer_ScriptAPI() {
        auto ControlledPlayer = App_CurrPlayground_GameTerminal_ControlledPlayer;
        if (ControlledPlayer is null) return null;
        return cast<CSmScriptPlayer>(ControlledPlayer.ScriptAPI);
    }

    int GetCurrentRaceTime(CGameCtnApp@ app) {
        if (app.Network.PlaygroundClientScriptAPI is null) return 0;
        int gameTime = app.Network.PlaygroundClientScriptAPI.GameTime;
        int startTime = -1;
        if (GUIPlayer_ScriptAPI !is null)
            startTime = GUIPlayer_ScriptAPI.StartTime;
        else if (ControlledPlayer_ScriptAPI !is null)
            startTime = ControlledPlayer_ScriptAPI.StartTime;
        if (startTime < 0) return 0;
        return gameTime - startTime;
        // return Math::Abs(gameTime - startTime);  // when formatting via Time::Format, negative ints don't work.
    }
}

namespace KoBufferUI {

    [Setting category="Buffer Time Display" name="Show Preview?" description="Shows a preview (works anywhere)"]
    bool Setting_ShowPreview = false;

    [Setting category="Buffer Time Display" name="Buffer Time Visible during KO matches?" description="Whether the timer shows up at all or not during KO matches. If unchecked, the plugin will not draw anything to the screen. This is the same setting as checking/unchecking this plugin in the Scripts menu."]
    bool g_koBufferUIVisible = true;

    [Setting category="Buffer Time Display" name="Plus for behind, Minus for ahead?" description="If true, when behind the timer will show a time like '+1.024', and '-1.024' when ahead. This is the minimum delta between players based on prior CPs. When this setting is false, the + and - signs are inverted, which shows the amount of buffer the player has (positive buffer being the number of seconds you can lose without being in a KO position)."]
    bool Setting_SwapPlusMinus = true;

    [Setting category="Buffer Time Display" name="Display Position" description="Origin: Top left. Values: Proportion of screen (range: 0-100%; default: (50, 87))" drag]
    vec2 Setting_BufferDisplayPosition = vec2(50, 87);

    // const string menuIcon = Icons::ArrowsH;
    const string menuIcon = " Δt";

    // int bufferDisplayFont = nvg::LoadFont("DroidSans.ttf", true, true);

    void RenderMenu() {
        if (UI::MenuItem("\\$faa\\$s" + menuIcon + "\\$z " + Meta::ExecutingPlugin().Name, MenuShortcutStr, g_koBufferUIVisible)) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
    }

    void RenderMenuMain() {
        if (!g_koBufferUIVisible) return;
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
        UI::Text("\\$bbb   Time Attack / Campaign Options");
        UI::Separator();

        if (UI::MenuItem("Show Vs. Best Ghost?", "", S_TA_VsBestGhost))
            S_TA_VsBestGhost = !S_TA_VsBestGhost;

        if (UI::MenuItem("Show Vs. PB?", "", S_TA_VsPB))
            S_TA_VsPB = !S_TA_VsPB;

        if (UI::MenuItem("Show Two Buf. Times?", "", S_TA_ShowTwoBufferTimes))
            S_TA_ShowTwoBufferTimes = !S_TA_ShowTwoBufferTimes;

        UI::Separator();

        UI::Text("\\$bbb   Currently prioritizing: " + tostring(S_TA_PrioritizedType));
        auto otherPriorityType = TaBufferTimeType((uint(S_TA_PrioritizedType) + 1 ) % 2);
        if (UI::MenuItem("Change priority to " + tostring(otherPriorityType)))
            S_TA_PrioritizedType = otherPriorityType;
    }

    void RenderUnknownMenuMainInner() {
        UI::Text("\\$f84 Unknown Game Mode! " + KoBuffer::lastGM);
        UI::TextWrapped("You should never see this. Sorry.\nPlease submit a bug report including at least the game mode and your settings.");
    }

    void ShowPreview() {
        int time = int(Time::Now);
        int msOffset = (time % 2000) - 1000;
        int cpOffset = Math::Abs((time % 2000) / 400 - 2);
        bool isBehind = msOffset < 0;
        msOffset = Math::Abs(msOffset);
        DrawBufferTime(msOffset, isBehind, GetBufferTimeColor(cpOffset, isBehind));
    }

    void Render() {
        if (Setting_ShowPreview) {
            ShowPreview();
            return;
        }
        if (!g_koBufferUIVisible) return;

        if (S_ShowBufferTimeInKO && KoBuffer::IsGameModeCotdKO)
            Render_KO();
        else if (S_ShowBufferTimeInTA && KoBuffer::IsGameModeTA)
            Render_TA();
    }

    WrapPlayerCpInfo@ ta_playerTime;
    WrapGhostInfo@ ta_bestGhost;
    WrapGhostInfo@ ta_pbGhost;

    // show buffer in TA against personal best
    void Render_TA() {
        auto crt = KoBuffer::GetCurrentRaceTime(GetApp());

        auto ghostData = MLFeed::GetGhostData();
        if (ghostData.NbGhosts == 0) return; // we need a ghost to get times from
        auto raceData = MLFeed::GetRaceData();
        auto playerName = KoBuffer::App_CurrPlayground_GameTerminal_GUIPlayerUserName;
        auto localPlayer = raceData.GetPlayer(playerName);
        if (localPlayer is null) return;

        if (!S_TA_VsBestGhost && !S_TA_VsPB) return;

        const MLFeed::GhostInfo@ bestGhost = S_TA_VsBestGhost ? ghostData.Ghosts[0] : null;
        const MLFeed::GhostInfo@ pbGhost = null;
        for (uint i = 0; i < ghostData.NbGhosts; i++) {
            auto g = ghostData.Ghosts[i];
            if (g.Nickname == "?Personal best" || g.Nickname == playerName) {
                if (S_TA_VsPB && (pbGhost is null || pbGhost.Result_Time > g.Result_Time)) {
                    @pbGhost = g;
                }
            }
            if (S_TA_VsBestGhost && bestGhost.Result_Time > g.Result_Time) {
                @bestGhost = g;
            }
        }

        if (ta_playerTime is null) @ta_playerTime = WrapPlayerCpInfo(localPlayer);
        else ta_playerTime.UpdateFrom(localPlayer);

        if (S_TA_VsBestGhost) {
            if (ta_bestGhost is null) @ta_bestGhost = WrapGhostInfo(bestGhost, crt);
            else ta_bestGhost.UpdateFrom(bestGhost, crt);
        } else {
            @ta_bestGhost = null;
        }

        // todo handle secondary timer for pb / choice between
        if (S_TA_VsPB) {
            if (ta_pbGhost is null) @ta_pbGhost = WrapGhostInfo(pbGhost, crt);
            else ta_pbGhost.UpdateFrom(pbGhost, crt);
        } else {
            @ta_pbGhost = null;
        }

        auto priorityGhost =
            ( S_TA_PrioritizedType == TaBufferTimeType::PersonalBest
              && pbGhost !is null && ta_pbGhost !is null
            ) ? ta_pbGhost : ta_bestGhost;
        if (priorityGhost is null) {
            @priorityGhost = ta_pbGhost !is null ? ta_pbGhost : ta_bestGhost;
        }
        if (priorityGhost is null) return;

        auto secondaryGhost = priorityGhost == ta_pbGhost ? ta_bestGhost : ta_pbGhost;

        bool showTwoTimes = S_TA_ShowTwoBufferTimes && priorityGhost != secondaryGhost && secondaryGhost !is null && secondaryGhost.cpCount > 0;
        // if (showTwoTimes) trace('show two times!');
        // else {
        //     trace('S_TA_ShowTwoBufferTimes: ' + tostring(S_TA_ShowTwoBufferTimes));
        //     trace('secondaryGhost: ' + secondaryGhost.ToString());
        //     trace('priorityGhost != secondaryGhost: ' + tostring(priorityGhost != secondaryGhost));
        // }
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

    [Setting category="Buffer Time Display" name="Font Choice"]
    FontChoice Setting_Font = FontChoice::Montserrat_Bold;

    [Setting category="Buffer Time Display" name="Display Font Size" min="10" max="150"]
    float Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;

    [Setting category="Buffer Time Display" name="Enable Stroke"]
    bool Setting_EnableStroke = true;

    [Setting category="Buffer Time Display" name="Stroke Width" min="1.0" max="20.0"]
    float Setting_StrokeWidth = 5.0;

    [Setting category="Buffer Time Display" name="Stroke Alpha" description="FYI it's not really alpha -- but it's an approximation; not perfect." min="0.0" max="1.0"]
    float Setting_StrokeAlpha = 1.0;

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
            fontSize /= 2;
            sw /= 1.5;
        }

        nvg::FontFace(fontChoiceToFont[uint(Setting_Font)]);
        nvg::FontSize(fontSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        auto sizeWPad = nvg::TextBounds(toDraw) + vec2(20, 10);

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
        vec2 offs = vec2(0, fontSize / 2. + 20) * (Setting_BufferDisplayPosition.y >= 50. ? 1 : -1);
        return pos + offs;
    }

    [Setting color category="Buffer Time Display" name="Color: Ahead within 1 CP"]
    vec4 Col_AheadDefinite = vec4(0.000f, 0.788f, 0.103f, 1.000f);
    [Setting color category="Buffer Time Display" name="Color: Behind within 1 CP"]
    vec4 Col_BehindDefinite = vec4(0.942f, 0.502f, 0.000f, 1.000f);

    [Setting color category="Buffer Time Display" name="Color: Far Ahead"]
    vec4 Col_FarAhead = vec4(0.008f, 1.000f, 0.000f, 1.000f);
    [Setting color category="Buffer Time Display" name="Color: Far Behind"]
    vec4 Col_FarBehind = vec4(0.961f, 0.007f, 0.007f, 1.000f);

    [Setting category="Buffer Time Display" name="Enable Buffer Time BG Color" description="Add a ((semi-)transparent) background box to the displayed Buffer Time."]
    bool Setting_DrawBufferTimeBG = true;

    [Setting color category="Buffer Time Display" name="Buffer Time BG Color" description="Background color of the timer if the above is enabled. (Transparency recommended.)"]
    vec4 Setting_BufferTimeBGColor = vec4(0.000f, 0.000f, 0.000f, 0.631f);

    vec4 GetBufferTimeColor(uint cpDelta, bool isBehind) {
        return cpDelta < 2
            ? (isBehind ? Col_BehindDefinite : Col_AheadDefinite)
            : (isBehind ? Col_FarBehind : Col_FarAhead);
    }

    [Setting category="Buffer Time Display" name="Hotkey Enabled?" description="Enable a hotkey that toggles displaying Buffer Time."]
    bool Setting_ShortcutKeyEnabled = false;

    [Setting category="Buffer Time Display" name="Hotkey Choice" description="Toggles displaying Buffer Time if the above is enabled."]
    VirtualKey Setting_ShortcutKey = VirtualKey::F5;

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

    [Setting category="Extra/Debug" name="Show All Players' Deltas" description="When checked a window will appear (if the interface is on) that shows all deltas for the current game (regardless of whether it's KO or not)."]
    bool S_ShowAllInfoDebug = false;

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
