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
        startnew(KoBuffer::Main);
    } else {
        if (!depMLHook) {
            NotifyDepError("Requires MLHook");
        }
        if (!depMLFeed) {
            NotifyDepError("Requires MLFeed: Race Data");
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
}

void RenderMenu() {
    KoBufferUI::RenderMenu();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    return KoBufferUI::OnKeyPress(down, key);
}

void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification("COTD Buffer Time: Dependency Error", msg, vec4(.9, .6, .1, .5), 15000);
}
