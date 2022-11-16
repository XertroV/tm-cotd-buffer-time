namespace Updates {
    bool hasUpdates {
        get {
            return false
                || !S_News_Viewed_2022_11_15;
        }
        set {
            S_News_Viewed_2022_11_15 = !value;
        }
    }

    void Render() {
        if (hasUpdates) {
            auto flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize;
            UI::SetNextWindowSize(520, 650, UI::Cond::Always);
            if (UI::Begin(Meta::ExecutingPlugin().Name + ": Updates!", hasUpdates, flags)) {
                UI::Text("Buffer Time -- Latest Updates");
                Update_2022_11_15();
            }
            UI::End();
        }
    }

    void Update_2022_11_15() {
        if (S_News_Viewed_2022_11_15) return;
        UI::Separator();
        UI::Text("Version 2.0.0");
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::BeginChild("news-2022-11-15")) {
            UI::Text("Summary: ");
            UI::TextWrapped(
                "This update adds support for \\$fb8Time Attack and Campaign\\$z game modes. "
                "As part of this change, this plugin is being renamed to just '\\$fb8Buffer Time\\$z'. "
            );
            UI::TextWrapped(
                "Although some new features are enabled by default, a \\$fb8new menubar item\\$z "
                "will let you quickly change relevant settings, or disable buffer time for certain game modes. "
            );
            UI::TextWrapped(
                "All previous settings should be honored."
            );
            UI::Separator();

            UI::Text("New Features: ");
            UI::TextWrapped("- MenuBar item for quick settings. It's only visible when Buffer Time is active.");
            UI::TextWrapped("- New Font (Oswald) that matches the in-game chronometer.");
            UI::TextWrapped("- Support for Time Attack / Campaign. (Other modes possible on request.)");
            UI::TextWrapped("- Support for showing Buffer Times vs any loaded ghost. (Note: the ghost only has to be loaded once, and can then be unloaded.)");
            UI::TextWrapped("- Support for a secondary buffer time (in TA) when two+ buffer times are avaiable. You can choose which is primary.");
            UI::TextWrapped("- Settings to manage new features, including disabling during COTD qualifier.");
            UI::Separator();

            UI::Text("Bug Fixes: ");
            UI::TextWrapped("- Fix temporarily incorrect times in KO when a player DNFs above the cutoff.");
            UI::Separator();

            UI::Text("Fonts:");
            for (uint i = 0; i < KoBufferUI::ui_fontChoiceToFont.Length; i++) {
                float t = float((Time::Now + i * 391) % 10000) / 1000 - 5.;
                TextWithFontDemo(tostring(KoBufferUI::FontChoice(i)), KoBufferUI::GetPlusMinusFor(t < 0) + Text::Format("%.3f", Math::Abs(t)), KoBufferUI::ui_fontChoiceToFont[i]);
            }
        }
        UI::EndChild();
    }




    void TextWithFontDemo(const string &in name, const string &in toDraw, UI::Font@ font) {
        vec2 pos = UI::GetCursorPos();
        UI::Text(name);
        vec2 postPos = UI::GetCursorPos();
        UI::SetCursorPos(pos + vec2(200, 0));
        UI::PushFont(font);
        UI::Text(toDraw);
        UI::PopFont();
        UI::SetCursorPos(postPos + vec2(0, 3));
    }
}
