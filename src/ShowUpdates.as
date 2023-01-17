namespace Updates {
    bool hasUpdates {
        get {
            return false
                || !S_News_Viewed_2022_11_15
                || !S_News_Viewed_2022_11_18
                || !S_News_Viewed_2022_11_23
                || !S_News_Viewed_2022_11_27
                || !S_News_Viewed_2022_11_29
                ;
        }
        set {
            if (value == false) {
                S_News_Viewed_2022_11_15 = true;
                S_News_Viewed_2022_11_18 = true;
                S_News_Viewed_2022_11_23 = true;
                S_News_Viewed_2022_11_27 = true;
                S_News_Viewed_2022_11_29 = true;
            }
        }
    }

    void MarkAllReadOnFirstBoot() {
        if (S_Meta_FirstLoad) {
            // don't set hasUpdates to false till a wizard/intro is implemented
            // hasUpdates = false;
            S_Meta_FirstLoad = false;
            S_Meta_EarliestVersion = Meta::ExecutingPlugin().Version;
        }
    }

    float _childWidth = 480;
    void Render() {
        if (S_Meta_FirstLoad) return;
        if (hasUpdates) {
            auto flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize;
            UI::SetNextWindowSize(520, 650, UI::Cond::Always);
            if (UI::Begin(Meta::ExecutingPlugin().Name + ": Updates!", hasUpdates, flags)) {
                _childWidth = UI::GetWindowContentRegionWidth() - 40;
                Heading("Buffer Time -- Latest Updates");
                Update_2022_11_29();
                Update_2022_11_27();
                Update_2022_11_23();
                Update_2022_11_18();
                Update_2022_11_15();
            }
            UI::End();
        }
    }

    void Update_2022_11_29() {
        if (S_News_Viewed_2022_11_29) return;
        UI::Separator();
        Heading("v2.2.0");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_29", vec2(_childWidth, 420))) {
            SubHeading("Factor-in Respawns");
            UI::TextWrapped("New setting enabled by default globally.");
            UI::TextWrapped("When this is active, the timer will update immediately to reflect that a player respawned. This works for you and for opponents (e.g., in COTD), but no such data is available for ghosts or other reference times.");
            UI::TextWrapped("To disable this setting, you can use this convenient checkbox:");
            S_UpdateInstantRespawns = UI::Checkbox("Update Instantly when Players Respawn?", S_UpdateInstantRespawns);
            UI::Separator();

            SubHeading("Final Time addition: No-Respawn Time");
            UI::TextWrapped("New setting enabled by default when the final time is shown.");
            UI::TextWrapped("When this is active, the a smaller final time will be shown corresponding to your no-respawn time. It will also show the number of respwns. The format is: 'M:SS.xxx; +R', where R is the respawn count and the rest is your no-respawn time. Works while spectating opponents.");
            UI::TextWrapped("Can be disabled via: menu > final time > show no-respawn time.");
            UI::Separator();

            SubHeading("Bug Fixes");
            UI::TextWrapped("- Hide during GPS: sometimes `Camera::GetCurrentPosition()` would bug out. When this is detected, the setting will be ignored and the timer will show regardless.");
            // UI::TextWrapped("- ");
            // UI::TextWrapped("- ");
        }
        UI::EndChild();
    }

    void Update_2022_11_27() {
        if (S_News_Viewed_2022_11_27) return;
        UI::Separator();
        Heading("v2.1.15");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_27", vec2(_childWidth, 300))) {
            UI::TextWrapped("Thanks to [\\$fc0" + Icons::StarO + "\\$z] AR_Down for the suggestions and bug reports.");
            UI::Separator();

            SubHeading("Show Vs. Time at Race Start (TA)");
            UI::TextWrapped("New setting enabled by default for Time Attack.");
            UI::TextWrapped("At the start of the race, the buffer timer will show the final time of the reference ghost/times.");
            UI::TextWrapped("This will only show in the first 5 seconds of the race, and only if you are stationary.");
            UI::Separator();

            SubHeading("Bug Fixes");
            UI::TextWrapped("- Fix: Timer hidden during alt cam 3 when 'Hide While GPS Active' setting is enabled. (2.1.14)");
            UI::TextWrapped("- Fix: Secondary timer wouldn't show when reading 0 (before 1st cp).");
            UI::TextWrapped("- Added warning when the game has so many ghosts loaded that it can cause lag. (2.1.16)");
        }
        UI::EndChild();
    }

    void Update_2022_11_23() {
        if (S_News_Viewed_2022_11_23) return;
        UI::Separator();
        Heading("v2.1.13");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_23", vec2(_childWidth, 130))) {
            SubHeading("Hide While GPS Active");
            UI::TextWrapped("New setting: 'Hide when GPS active?'. Note: this is also active while in cam 7 due to limitations of the implementation.");
            UI::TextWrapped("To disable this setting, you can use this convenient checkbox:");
            S_HideWhenGPSActive = UI::Checkbox("Hide When GPS Active?", S_HideWhenGPSActive);
        }
        UI::EndChild();
    }

    void Update_2022_11_18() {
        if (S_News_Viewed_2022_11_18) return;
        UI::Separator();
        Heading("v2.1");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_18", vec2(_childWidth, 380))) {
            SubHeading("Vs. Player");
            UI::TextWrapped("New Feature: set another player's best race times as a reference target. This is not their PB, just their best times set this session.");
            UI::Separator();

            SubHeading("Final Time");
            UI::TextWrapped("New Feature: Show your final time when you finish a race. Useful if you play with the HUD off. It can be disabled from the quick settings menu.");
            UI::Markdown("**Default: show when the interface is hidden.**");
            UI::Separator();

            SubHeading("Bug Fixes");
            UI::TextWrapped("- Ghosts created on a prior maps on a server will be filtered out.");
            UI::TextWrapped("- Better manage conflicting prioritization choices.");
            UI::TextWrapped("- PB times in Solo mode now auto-populate correctly.");
            UI::TextWrapped("- Better organize TA quick settings menu.");
            UI::TextWrapped("- Big render time improvement in TA.");
            UI::TextWrapped("- Fix: timer wouldn't show if there were 0 ghosts.");
            UI::TextWrapped("- Fix: duplicate ghosts in menu selection.");
            UI::TextWrapped("- Fix: crash when selecting 'BestTimeOrPB'.");
        }
        UI::EndChild();
    }

    void Update_2022_11_15() {
        if (S_News_Viewed_2022_11_15) return;
        UI::Separator();
        Heading("v2.0");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_15", vec2(_childWidth, 760))) {
            SubHeading("Summary: ");
            UI::TextWrapped(
                "This update adds support for \\$fb8Time Attack and Campaign\\$z game modes. "
                "As part of this change, this plugin is being renamed to just '\\$fb8Buffer Time\\$z'. "
            );
            UI::TextWrapped(
                "Although some new features are enabled by default, a \\$fb8new menubar item\\$z "
                "will let you quickly change relevant settings, or disable buffer time for certain game modes. "
            );
            UI::Separator();

            SubHeading("New Features: ");
            UI::TextWrapped("- MenuBar item for quick settings. It's only visible when Buffer Time is active.");
            UI::TextWrapped("- New Font (Oswald) that matches the in-game chronometer.");
            UI::TextWrapped("- Support for Time Attack / Campaign. Other modes possible on request.");
            UI::TextWrapped("- Support for showing Buffer Times vs any loaded ghost. (Note: the ghost only has to be loaded once, and can then be unloaded.)");
            UI::TextWrapped("- Support for a secondary buffer time (in TA) when two+ buffer times are available. You can choose which is primary.");
            UI::TextWrapped("- Settings to manage new features, including disabling during COTD qualifier.");
            UI::Separator();

            SubHeading("Bug Fixes: ");
            UI::TextWrapped("- Fix temporarily incorrect times in KO when a player DNFs above the cutoff.");
            UI::Separator();

            SubHeading("Fonts:");
            for (uint i = 0; i < KoBufferUI::ui_fontChoiceToFont.Length; i++) {
                auto font = KoBufferUI::ui_fontChoiceToFont[i];
                if (font !is null) {
                    float t = float((Time::Now + i * 391) % 10000) / 1000 - 5.;
                    TextWithFontDemo(tostring(KoBufferUI::FontChoice(i)), KoBufferUI::GetPlusMinusFor(t < 0) + Text::Format("%.3f", Math::Abs(t)), KoBufferUI::ui_fontChoiceToFont[i]);
                } else {
                    KoBufferUI::LoadImGuiFonts();
                }
            }
        }
        UI::EndChild();
    }

    void TextWithFontDemo(const string &in name, const string &in toDraw, UI::Font@ font) {
        vec2 pos = UI::GetCursorPos();
        UI::Text(" " + name);
        vec2 postPos = UI::GetCursorPos();
        UI::SetCursorPos(pos + vec2(200, 0));
        UI::PushFont(font);
        UI::Text(toDraw);
        UI::PopFont();
        UI::SetCursorPos(postPos + vec2(0, 3));
    }
}
