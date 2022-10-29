const float TAU = 6.283185307179586;



namespace KoBuffer {
/* bugs:
- when at 0, no behind shows up even if it should:
  d = RaceTime - ahead.lastCP
  nb: racetime here is sorta the curr pos of the ahead car

*/
    void Main() {
        startnew(InitCoro);
    }

    void InitCoro() {
        startnew(MainCoro);
    }

    void MainCoro() {
        while (true) {
            yield();
            CheckGMChange();
        }
    }

    string lastGM = "nonexistent init";
    void CheckGMChange() {
        if (CurrentGameMode != lastGM) {
            lastGM = CurrentGameMode;
            // if (IsGameModeCotdKO) {
            // }
        }
    }

    bool get_IsGameModeCotdKO() {
        return lastGM == "TM_KnockoutDaily_Online"
            || lastGM == "TM_Knockout_Debug"
            || lastGM == "TM_Knockout_Online";
    }
}

namespace KoBufferUI {

    [Setting hidden]
    bool g_koBufferUIVisible = true;

    [Setting category="KO Buffer Time" name="Show Preview?" color]
    bool Setting_ShowPreview = false;

    [Setting category="KO Buffer Time" name="Plus for behind, Minus for ahead?" description="If true, when behind the timer will show a time like '+1.024', and '-1.024' when ahead. This is the minimum delta between players based on prior CPs. When this setting is false, the + and - signs are inverted, which shows the amount of buffer the player has (positive buffer being the number of seconds you can lose without being in a KO position)."]
    bool Setting_SwapPlusMinus = true;

    [Setting category="KO Buffer Time" name="Show SAFE indicator when elimination is imposible?" description="If true, when enough players DNF or disconnect, the timer will change to the SAFE indicator (99.999 green)."]
    bool Setting_ShowSafeIndicatorEver = true;

    [Setting category="KO Buffer Time" name="Show OUT indicator when elimination is inevitable?" description="If true, when you're guarenteed to be knocked out, the timer will change to the OUT indicator (99.999 red)."]
    bool Setting_ShowOutIndicatorEver = true;

    [Setting category="KO Buffer Time" name="Show SAFE indicator during No KO round?" description="If true, during the No KO round the timer will change to the SAFE indicator (99.999 green)."]
    bool Setting_SafeIndicatorInNoKO = true;

    [Setting category="KO Buffer Time" name="Display Position" description="Origin: Top left. Values: Proportion of screen (range: 0-100%; default: (50, 87))" drag]
    vec2 Setting_BufferDisplayPosition = vec2(50, 87);

    // const string menuIcon = Icons::ArrowsH;
    const string menuIcon = " Δt";

    // int bufferDisplayFont = nvg::LoadFont("DroidSans.ttf", true, true);

    void RenderMenu() {
        if (UI::MenuItem("\\$faa\\$s" + menuIcon + "\\$z COTD Buffer Time", MenuShortcutStr, g_koBufferUIVisible)) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
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
        if (!KoBuffer::IsGameModeCotdKO) return;

        // calc player's position relative to ko position
        // target: either player right before or after ko pos
        // if (koFeedHook is null || theHook is null) return;
        auto theHook = MLFeed::GetRaceData();
        auto koFeedHook = MLFeed::GetKoData();

        if (!Setting_SafeIndicatorInNoKO) {
            if (koFeedHook.RoundNb == 0) return;
            if (koFeedHook.KOsNumber == 0) return;
        }

        // string localUser = LocalUserName;
        string localUser = GUIPlayerUserName;
        uint localUserRank = 0;
        uint nPlayers = koFeedHook.PlayersNb;
        uint nKOs = koFeedHook.KOsNumber;
        uint preCutoffRank = nPlayers - nKOs;
        uint postCutoffRank = preCutoffRank + 1;
        MLFeed::PlayerCpInfo@ preCpInfo = null;
        MLFeed::PlayerCpInfo@ postCpInfo = null;
        MLFeed::PlayerCpInfo@ localPlayer = null;
        auto @sorted = theHook.SortedPlayers_Race;
        // todo: if postCpInfo is null it might be because there aren't enough players, so count as 0 progress?

        for (uint i = 0; i < sorted.Length; i++) {
            // uint currRank = i + 1;
            auto player = sorted[i];
            if (player is null) continue; // edge case on changing maps and things
            if (player.name == localUser) @localPlayer = player;
            if (player.raceRank == preCutoffRank) @preCpInfo = player;
            if (player.raceRank == postCutoffRank) @postCpInfo = player;
        }

        if (localPlayer is null) return;

        auto bufferTime = CalcBufferTime(theHook, koFeedHook, preCpInfo, postCpInfo, localPlayer, postCutoffRank, true);
        if (bufferTime.isOut && Setting_ShowOutIndicatorEver) {
            DrawBufferTime(99999, true, GetBufferTimeColor(99, true));
        } else if (bufferTime.isSafe && (Setting_ShowSafeIndicatorEver || (koFeedHook.KOsNumber == 0 && Setting_SafeIndicatorInNoKO))) {
            DrawBufferTime(99999, false, GetBufferTimeColor(99, false));
        } else {
            vec4 bufColor = GetBufferTimeColor(bufferTime.cpDelta, bufferTime.isBehind);
            DrawBufferTime(bufferTime.msDelta, bufferTime.isBehind, bufColor);
        }
    }

    BufferTime@ CalcBufferTime(const MLFeed::RaceDataProxy@ theHook, const MLFeed::KoDataProxy@ koFeedHook,
                        MLFeed::PlayerCpInfo@ preCpInfo, MLFeed::PlayerCpInfo@ postCpInfo,
                        MLFeed::PlayerCpInfo@ localPlayer,
                        uint postCutoffRank,
                        bool drawBufferTime = false
    ) {
        if (localPlayer is null) return BufferTime(null, 0, 1, true, false, false, false, false);

        auto localPlayerState = koFeedHook.GetPlayerState(localPlayer.name);
        bool localPlayerLives = !localPlayerState.isDNF && localPlayerState.isAlive;

        if (preCpInfo is null) return BufferTime(localPlayer, 99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);

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
            return BufferTime(localPlayer, 99999, 99, true, false, true, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        if (isSafe && drawBufferTime && Setting_ShowSafeIndicatorEver) {
            return BufferTime(localPlayer, 99999, 99, false, true, false, localPlayerState.isAlive, localPlayerState.isDNF);
        }


        MLFeed::PlayerCpInfo@ targetCpInfo;
        int msDelta;
        bool isBehind;
        bool sameCp;

        // ahead of 1st player to be eliminated?
        if (localPlayer.raceRank < postCutoffRank) @targetCpInfo = postCpInfo;
        else @targetCpInfo = preCpInfo; // otherwise, if at risk of elim

        if (targetCpInfo is null) {
            return BufferTime(localPlayer, 99999, 99, false, localPlayerLives, !localPlayerLives, localPlayerState.isAlive, localPlayerState.isDNF);
        }

        isBehind = localPlayer.raceRank > targetCpInfo.raceRank; // should never be ==
        // are we at same CP?
        sameCp = localPlayer.cpCount == targetCpInfo.cpCount;
        uint cpDelta = Math::Abs(localPlayer.cpCount - targetCpInfo.cpCount);

        auto aheadPlayer = isBehind ? targetCpInfo : localPlayer;
        auto behindPlayer = isBehind ? localPlayer : targetCpInfo;
        uint expectedExtraCps = 0;
        if (aheadPlayer.cpCount > behindPlayer.cpCount) {
            expectedExtraCps = Math::Max(CurrentRaceTime - behindPlayer.lastCpTime, aheadPlayer.cpTimes[behindPlayer.cpCount + 1] - aheadPlayer.cpTimes[behindPlayer.cpCount]);
            msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount + 1] + expectedExtraCps;
        } else if (aheadPlayer.cpCount < behindPlayer.cpCount) {
            // should never be true
            msDelta = 98765;
        } else {
            msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount];
        }
        // if (msDelta < 0) msDelta = minBuffer;
        // we replace msDelta with min buffer in this sorta situation:
        // - 3rd place will be eliminated
        // - you were in 3rd
        // - so buffer is negative and diff between cp times
        // - but then you cross cp first before other guy
        // - so you're the ahead player, however, the diff CP times for prior CP was negative
        // - you haven't gained the -'ve amount in buffer, tho, b/c the other player might get CP in 0.001s or whatever.
        // - so all you know is that you have no negative buffer
        // - and you know how much +'ve buffer you have once the guy crosses the line, which happens X seconsd later
        // - so at a minimum the buffer is CurrentRaceTime - ahead.lastCp

        return BufferTime(localPlayer, msDelta, cpDelta, isBehind, isSafe, isOut, localPlayerState.isAlive, localPlayerState.isDNF);
    }

    class BufferTime {
        MLFeed::PlayerCpInfo@ localPlayer;
        uint msDelta;
        uint cpDelta;
        bool isBehind;
        bool isSafe;
        bool isOut;
        bool isAlive;
        bool isDNF;
        BufferTime(MLFeed::PlayerCpInfo@ _localPlayer, uint _msDelta, uint _cpDelta, bool _isBehind, bool _isSafe, bool _isOut, bool _isAlive, bool _isDNF) {
            @localPlayer = _localPlayer;
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

    enum FontChoice {
        Medium = 0,
        Medium_Italic,
        SemiBold,
        SemiBold_Italic,
        Bold,
        Bold_Italic
    }

    array<int> fontChoiceToFont =
        { mediumDisplayFont
        , mediumItalicDisplayFont
        , semiBoldDisplayFont
        , semiBoldItalicDisplayFont
        , boldDisplayFont
        , boldItalicDisplayFont
        };

    [Setting category="KO Buffer Time" name="Font Choice"]
    FontChoice Setting_Font = FontChoice::Bold;

    [Setting category="KO Buffer Time" name="Display Font Size" min="10" max="150"]
    float Setting_BufferFontSize = 60;

    [Setting category="KO Buffer Time" name="Enable Stroke"]
    bool Setting_EnableStroke = true;

    [Setting category="KO Buffer Time" name="Stroke Width" min="1.0" max="20.0"]
    float Setting_StrokeWidth = 5.0;

    [Setting category="KO Buffer Time" name="Stroke Alpha" description="FYI it's not really alpha -- but it's an approximation; not perfect." min="0.0" max="1.0"]
    float Setting_StrokeAlpha = 1.0;

    string GetPlusMinusFor(bool isBehind) {
        return (isBehind ^^ Setting_SwapPlusMinus) ? "-" : "+";
    }

    void DrawBufferTime(int msDelta, bool isBehind, vec4 bufColor) {
        msDelta = Math::Abs(msDelta);
        nvg::Reset();
        string toDraw = GetPlusMinusFor(isBehind) + MsToSeconds(msDelta);
        auto screen = vec2(Draw::GetWidth(), Draw::GetHeight());
        vec2 pos = (screen * Setting_BufferDisplayPosition / vec2(100, 100));// - (size / 2);

        nvg::FontFace(fontChoiceToFont[uint(Setting_Font)]);
        nvg::FontSize(Setting_BufferFontSize);
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
            float sw = Setting_StrokeWidth;
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

    [Setting color category="KO Buffer Time" name="Color: Ahead within 1 CP"]
    vec4 Col_AheadDefinite = vec4(0.000f, 0.788f, 0.103f, 1.000f);
    [Setting color category="KO Buffer Time" name="Color: Behind within 1 CP"]
    vec4 Col_BehindDefinite = vec4(0.942f, 0.502f, 0.000f, 1.000f);

    [Setting color category="KO Buffer Time" name="Color: Far Ahead"]
    vec4 Col_FarAhead = vec4(0.008f, 1.000f, 0.000f, 1.000f);
    [Setting color category="KO Buffer Time" name="Color: Far Behind"]
    vec4 Col_FarBehind = vec4(0.961f, 0.007f, 0.007f, 1.000f);

    [Setting category="KO Buffer Time" name="Enable Buffer Time BG Color" description="Add a ((semi-)transparent) background box to the displayed Buffer Time."]
    bool Setting_DrawBufferTimeBG = true;

    [Setting color category="KO Buffer Time" name="Buffer Time BG Color" description="Background color of the timer if the above is enabled. (Transparency recommended.)"]
    vec4 Setting_BufferTimeBGColor = vec4(0.000f, 0.000f, 0.000f, 0.631f);

    vec4 GetBufferTimeColor(uint cpDelta, bool isBehind) {
        return cpDelta < 2
            ? (isBehind ? Col_BehindDefinite : Col_AheadDefinite)
            : (isBehind ? Col_FarBehind : Col_FarAhead);
    }

    [Setting category="KO Buffer Time" name="Hotkey Enabled?" description="Enable a hotkey that toggles displaying Buffer Time."]
    bool Setting_ShortcutKeyEnabled = false;

    [Setting category="KO Buffer Time" name="Hotkey Choice" description="Toggles displaying Buffer Time if the above is enabled."]
    VirtualKey Setting_ShortcutKey = VirtualKey::F5;

    string get_MenuShortcutStr() {
        if (Setting_ShortcutKeyEnabled)
            return tostring(Setting_ShortcutKey);
        return "";
    }

    UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
        if (Setting_ShortcutKeyEnabled && down && key == Setting_ShortcutKey) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
        return UI::InputBlocking::DoNothing;
    }

    /* DEBUG WINDOW: SHOW ALL */

    [Setting category="Extra/Debug" name="Show All Players' Deltas during KO" description="When checked a window will appear (if the interface is on) during KO matches that shows all deltas."]
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
                    for (uint i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        auto player = sorted[i];
                        auto bt = CalcBufferTime(theHook, koFeedHook, preCpInfo, postCpInfo, player, postCutoffRank);
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
