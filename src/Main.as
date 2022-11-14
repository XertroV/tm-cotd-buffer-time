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
        print("cotd buffer time starting.");
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
    KoBufferUI::Render();
}

void RenderInterface() {
    KoBufferUI::RenderInterface();
}

void RenderMenu() {
    KoBufferUI::RenderMenu();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    return KoBufferUI::OnKeyPress(down, key);
}

/** Called when a setting in the settings panel was changed. */
void OnSettingsChanged() {
    if (KoBufferUI::Setting_BufferFontSize < 0.1) {
        KoBufferUI::Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;
    }
}

void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Dependency Error", msg, vec4(.9, .6, .1, .5), 15000);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .6, .1, .5), 15000);
}
