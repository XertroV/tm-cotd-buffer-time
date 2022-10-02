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
    // const string menuIcon = Icons::ArrowsH;
    const string menuIcon = " Δt";

    int boldItalicDisplayFont = nvg::LoadFont("fonts/MontserratMono-BoldItalic.ttf", true, true);
    int boldDisplayFont = nvg::LoadFont("fonts/MontserratMono-Bold.ttf", true, true);
    // int bufferDisplayFont = nvg::LoadFont("DroidSans.ttf", true, true);

    void RenderMenu() {
        if (UI::MenuItem("\\$faa\\$s" + menuIcon + "\\$z COTD Buffer Time", MenuShortcutStr, g_koBufferUIVisible)) {
            g_koBufferUIVisible = !g_koBufferUIVisible;
        }
    }

    [Setting category="KO Buffer Time" name="Use Italic Font?"]
    bool Setting_BufferFontItalic = false;

    int get_bufferDisplayFont() {
        if (Setting_BufferFontItalic) return boldItalicDisplayFont;
        return boldDisplayFont;
    }

    void Render() {
        if (!g_koBufferUIVisible) return;
        if (!KoBuffer::IsGameModeCotdKO) return;

        // calc player's position relative to ko position
        // target: either player right before or after ko pos
        // if (koFeedHook is null || theHook is null) return;
        auto theHook = MLFeed::GetRaceData();
        auto koFeedHook = MLFeed::GetKoData();
        if (koFeedHook.RoundNb == 0) return;
        if (koFeedHook.KOsNumber == 0) return;
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

        bool isOut = (int(localPlayer.raceRank) > koFeedHook.PlayersNb - koFeedHook.KOsNumber)
                && preCpInfo.cpCount == int(theHook.CPsToFinish);

        if (localPlayer is null) return;
        if (localPlayer is null || preCpInfo is null || postCpInfo is null) {
#if DEV
            trace('a cp time player was null!');
            // trace(localPlayer is null ? 'y' : 'n');
            // trace(preCpInfo is null ? 'y' : 'n');
            // trace(postCpInfo is null ? 'y' : 'n');
#endif
            return;
        }


        if (isOut) {
            DrawBufferTime(99999, true, GetBufferTimeColor(99, true));
            return;
        }


        MLFeed::PlayerCpInfo@ targetCpInfo;
        int msDelta;
        bool isBehind;
        bool sameCp;
        bool newWay = true;

        // ahead of 1st player to be eliminated?
        if (localPlayer.raceRank < postCutoffRank) @targetCpInfo = postCpInfo;
        else @targetCpInfo = preCpInfo; // otherwise, if at risk of elim
        isBehind = localPlayer.raceRank > targetCpInfo.raceRank; // should never be ==
        // are we at same CP?
        sameCp = localPlayer.cpCount == targetCpInfo.cpCount;
        uint cpDelta = Math::Abs(localPlayer.cpCount - targetCpInfo.cpCount);

        // old way
        if (!newWay) {

            if (sameCp)
                msDelta = Math::Abs(localPlayer.lastCpTime - targetCpInfo.lastCpTime);
            else { // otherwise, we're at least (GameTime - player[cp]) ahead/behind
                uint cpToCompare = Math::Max(targetCpInfo.cpCount, localPlayer.cpCount);
                // diff between
                auto aheadPlayer = isBehind ? targetCpInfo : localPlayer;
                auto behindPlayer = isBehind ? localPlayer : targetCpInfo;

                if (isBehind)
                    msDelta = CurrentRaceTime - targetCpInfo.cpTimes[cpToCompare];
                else
                    msDelta = CurrentRaceTime - localPlayer.cpTimes[cpToCompare];
            }
        }

        // new way
        if (newWay) {
            auto aheadPlayer = isBehind ? targetCpInfo : localPlayer;
            auto behindPlayer = isBehind ? localPlayer : targetCpInfo;
            uint minBuffer = aheadPlayer.cpCount == 0 ? 0 : (CurrentRaceTime - aheadPlayer.lastCpTime);
            uint expectedExtraCps = 0;
            if (aheadPlayer.cpCount > behindPlayer.cpCount) {
                expectedExtraCps = Math::Max(CurrentRaceTime - behindPlayer.lastCpTime, aheadPlayer.cpTimes[behindPlayer.cpCount + 1] - aheadPlayer.cpTimes[behindPlayer.cpCount]);
                msDelta = behindPlayer.lastCpTime - aheadPlayer.cpTimes[behindPlayer.cpCount + 1] + expectedExtraCps;
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
        }

        vec4 bufColor = GetBufferTimeColor(cpDelta, isBehind);

        DrawBufferTime(msDelta, isBehind, bufColor);
    }

    [Setting category="KO Buffer Time" name="Display Font Size" min="10" max="150"]
    float Setting_BufferFontSize = 60;

    [Setting category="KO Buffer Time" name="Enable Stroke"]
    bool Setting_EnableStroke = true;

    [Setting category="KO Buffer Time" name="Stroke Width" min="1.0" max="20.0"]
    float Setting_StrokeWidth = 5.0;


    [Setting drag category="KO Buffer Time" name="Display Position" description="Origin: Top left. Values: Proportion of screen (range: 0-100 %)"]
    vec2 Setting_BufferDisplayPosition = vec2(50, 87);

    void DrawBufferTime(int msDelta, bool isBehind, vec4 bufColor) {
        nvg::Reset();
        string toDraw = (isBehind ? "-" : "+") + MsToSeconds(msDelta);
        auto screen = vec2(Draw::GetWidth(), Draw::GetHeight());
        vec2 pos = (screen * Setting_BufferDisplayPosition / vec2(100, 100));// - (size / 2);

        nvg::FontFace(bufferDisplayFont);
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
            nvg::FillColor(vec4(0,0,0,1));
            float nCopies = 32; // this does not seem to be expensive
            for (float i = 0; i < nCopies; i++) {
                float angle = TAU * float(i) / nCopies;
                vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
                nvg::Text(pos + offs, toDraw);
            }
        }

        nvg::FillColor(bufColor);
        nvg::Text(pos, toDraw);
    }

    [Setting color category="KO Buffer Time" name="Color: Ahead w/in 1 CP"]
    vec4 Col_AheadDefinite = vec4(0.000f, 0.788f, 0.103f, 1.000f);
    [Setting color category="KO Buffer Time" name="Color: Behind w/in 1 CP"]
    vec4 Col_BehindDefinite = vec4(0.942f, 0.502f, 0.000f, 1.000f);

    [Setting color category="KO Buffer Time" name="Color: Far Ahead (actively counts)"]
    vec4 Col_FarAhead = vec4(0.008f, 1.000f, 0.000f, 1.000f);
    [Setting color category="KO Buffer Time" name="Color: Far Behind (actively counts)"]
    vec4 Col_FarBehind = vec4(0.961f, 0.007f, 0.007f, 1.000f);

    [Setting category="KO Buffer Time" name="Enable Buffer Time BG Color"]
    bool Setting_DrawBufferTimeBG = true;
    [Setting color category="KO Buffer Time" name="Buffer Time BG Color" description="Add a background to the timer"]
    vec4 Setting_BufferTimeBGColor = vec4(0.000f, 0.000f, 0.000f, 0.631f);

    vec4 GetBufferTimeColor(uint cpDelta, bool isBehind) {
        return cpDelta < 2
            ? (isBehind ? Col_BehindDefinite : Col_AheadDefinite)
            : (isBehind ? Col_FarBehind : Col_FarAhead);
    }

    [Setting category="KO Buffer Time" name="Shortcut Key Enabled?"]
    bool Setting_ShortcutKeyEnabled = false;

    [Setting category="KO Buffer Time" name="Shortcut Key Choice"]
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
}
