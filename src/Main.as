void Main() {
    bool depMLHook = false;
    bool depMLFeed = false;
#if DEPENDENCY_MLHOOK
    depMLHook = true;
#endif
#if DEPENDENCY_MLFEEDRACEDATA
    depMLFeed = true;
#endif
    if (depMLFeed && depMLHook) {
        print("buffer time starting.");
        startnew(KoBuffer::Main);
    } else {
        if (!depMLHook) {
            NotifyDepError("Requires MLHook");
        } else if (!depMLFeed) {
            NotifyDepError("Requires MLFeed: Race Data");
        } else {
            NotifyDepError("Unknown dependency error.");
        }
    }
}


void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
}

void Render() {
    Updates::Render();
    KoBufferUI::Render();
}

void RenderInterface() {
    KoBufferUI::RenderInterface();
}

void RenderMenu() {
    KoBufferUI::RenderMenu();
}

/** Render function called every frame intended only for menu items in the main menu of the `UI`.
*/
void RenderMenuMain() {
    KoBufferUI::RenderMenuMain();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    return KoBufferUI::OnKeyPress(down, key);
}

/** Called when a setting in the settings panel was changed. */
void OnSettingsChanged() {
    if (Setting_BufferFontSize < 0.1) {
        Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;
    }
}

/*
    Utility functions
*/

//
void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Dependency Error", msg, vec4(.9, .6, .1, .5), 15000);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .6, .1, .5), 15000);
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}

const string MsToSeconds(int t) {
    return Text::Format("%.3f", float(t) / 1000.0);
}
