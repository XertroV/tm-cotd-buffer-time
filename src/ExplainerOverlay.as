namespace KoBufferUI {
    vec2 lastHoverSize = vec2(200);
    void RenderHoverExplainerOverlay(bool inMM, bool inKO, bool inTA) {
        vec2 nextPos = g_LastMousePos + vec2(10.0 * UI::GetScale(), lastHoverSize.y * -1);
        nextPos.y = Math::Max(0., nextPos.y);
        UI::SetNextWindowPos(int(nextPos.x), int(nextPos.y), UI::Cond::Always);
        int flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoInputs | UI::WindowFlags::AlwaysAutoResize;
        if (UI::Begin("buffer time hover explainer", flags)) {
            auto pos = UI::GetCursorPos();
            UI::Dummy(vec2(250, 10));
            UI::SetCursorPos(pos);
            if (inMM) RenderHoverExplainerMM();
            if (inKO) RenderHoverExplainerKO();
            if (inTA) RenderHoverExplainerTA();
            lastHoverSize = UI::GetWindowSize();
        }
        UI::End();
    }

    void RenderHoverExplainerMM() {
        UI::Text("Matchmaking:");
        UI::TextWrapped("Main timer: you vs. critical opponent (losing to them means losing the match). Changes based on current race positions.");
        UI::TextWrapped(
            "2nd timer: vs. MVP player\n"
            "2nd timer after fin: points delta to MVP"
        );
        UI::TextWrapped(
            "99.999 means that your position has no bearing on whether your team will win/lose the match."
        );
    }
    void RenderHoverExplainerKO() {
        UI::Text("Knockout:");
        UI::TextWrapped("Main timer: your buffer to the KO position. Risk when yellow, safe when green.");
        UI::TextWrapped("99.999 indicates that you are either: already KOd, or will survive if you finish.");
    }
    void RenderHoverExplainerTA() {
        // UI::AlignTextToFramePadding();
        UI::Text("Time Attack:");
        UI::TextWrapped("Main timer: you vs. the 1st available source.");
        UI::TextWrapped("2nd timer: vs. 2nd available source, excl. duplicates.");
        if (UI::BeginTable("priority table hover", 2, UI::TableFlags::SizingStretchProp)) {
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("  Priority 1: \\$bbb("+tostring(S_TA_Priority1Type)+")");
            UI::TableNextColumn();
            UI::Text(WrappedTimesLabel(priorityGhostRaw));
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("  Priority 2: \\$bbb("+tostring(S_TA_Priority2Type)+")");
            UI::TableNextColumn();
            UI::Text(WrappedTimesLabel(secondaryGhostRaw));
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("  Priority 3: \\$bbb("+tostring(S_TA_Priority3Type)+")");
            UI::TableNextColumn();
            UI::Text(WrappedTimesLabel(tertiaryGhostRaw));
            UI::EndTable();
        }
    }
}
