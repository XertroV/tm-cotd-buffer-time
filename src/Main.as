void Main() {
    startnew(KoBuffer::Main);
#if DEV
        // KoFeedUI::g_windowVisible = true;
#endif
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
