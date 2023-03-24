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
        sleep(3000); // plugin manager will reload improperly if updates happen simultaneously
        if (!depMLHook) {
            NotifyDepError("Requires MLHook");
        } else if (!depMLFeed) {
            NotifyDepError("Requires MLFeed: Race Data");
        } else {
            NotifyDepError("Unknown dependency error.");
        }
    }
    // print("Camera currnet pos: " + Camera::GetCurrentPosition().ToString());
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
}

bool g_IsTimerHovered = false;

/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    g_IsTimerHovered = false;
}

void Render() {
    Updates::Render();
    KoBufferUI::Render();
    KoBufferUI::Render_TA_StateDebugScreen();
    KoBufferUI::Render_MM_StateDebugScreen();
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
    if (Setting_BufferFontSize < 0.1)
        Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;
    if (S_FT_FontSize < 0.1)
        S_FT_FontSize = 120 * Draw::GetHeight() / 1440;
    startnew(OnSettingsChanged_TA_EnsureCorrectPriority);
}

vec2 g_LastMousePos;
/** Called whenever the mouse moves. `x` and `y` are the viewport coordinates.
*/
void OnMouseMove(int x, int y) {
    g_LastMousePos.x = x;
    g_LastMousePos.y = y;
}


/*
    Utility functions
*/

//
void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Dependency Error", msg + "\n\nNote: if you see this while updating multiple plugins, you can probably ignore it.", vec4(.9, .6, .1, .5), 15000);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .6, .1, .3), 10000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.6, .6, .1, .3), 5000);
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

bool IsWithin(vec2 pos, vec2 topLeft, vec2 size) {
    vec2 d1 = topLeft - pos;
    vec2 d2 = (topLeft + size) - pos;
    return (d1.x >= 0 && d1.y >= 0 && d2.x <= 0 && d2.y <= 0)
        || (d1.x <= 0 && d1.y <= 0 && d2.x >= 0 && d2.y >= 0)
        || (d1.x <= 0 && d1.y >= 0 && d2.x >= 0 && d2.y <= 0)
        || (d1.x >= 0 && d1.y <= 0 && d2.x <= 0 && d2.y >= 0)
        ;
}
