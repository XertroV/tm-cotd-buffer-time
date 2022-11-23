namespace Updates {
    bool hasUpdates {
        get {
            return false
                || !S_News_Viewed_2022_11_15
                || !S_News_Viewed_2022_11_18
                || !S_News_Viewed_2022_11_23
                ;
        }
        set {
            if (value == false) {
                S_News_Viewed_2022_11_15 = true;
                S_News_Viewed_2022_11_18 = true;
                S_News_Viewed_2022_11_23 = true;
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
                Update_2022_11_23();
                Update_2022_11_18();
                Update_2022_11_15();
            }
            UI::End();
        }
    }

    void Update_2022_11_23() {
        if (S_News_Viewed_2022_11_23) return;
        UI::Separator();
        Heading("v2.1.13");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022_11_23", vec2(_childWidth, 380))) {
            SubHeading("Hide While GPS Active");
            UI::TextWrapped("New setting: 'Hide when GPS active?'. Note: this is also active while in cam 7 due to limitations of the implementation.");
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
                float t = float((Time::Now + i * 391) % 10000) / 1000 - 5.;
                TextWithFontDemo(tostring(KoBufferUI::FontChoice(i)), KoBufferUI::GetPlusMinusFor(t < 0) + Text::Format("%.3f", Math::Abs(t)), KoBufferUI::ui_fontChoiceToFont[i]);
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
