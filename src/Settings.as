[Setting category="Global" name="Enable?" description="Whether the timer shows up at all or not. If unchecked, the plugin will not draw anything to the screen. This is the same setting as checking/unchecking this plugin in the Scripts menu."]
bool g_koBufferUIVisible = true;

bool g_KoBufferUIHidden {
    get { return !g_koBufferUIVisible; }
    set { g_koBufferUIVisible = !value; }
}

[Setting category="Global" name="Show Final Time?" description="When you finish a race, your final time will be shown if UI settings match (see next setting)."]
bool S_ShowFinalTime = true;

[Setting category="Global" name="Show Final TIme only when Interface Hidden?" description="The final time will show only when the interface is hidden."]
bool S_FT_OnlyWhenInterfaceHidden = true;

[Setting category="Global" name="Show Buffer Time during TA / Solo?"]
bool S_ShowBufferTimeInTA = true;

[Setting category="Global" name="Show Buffer Time during KO / COTD KO?"]
bool S_ShowBufferTimeInKO = true;

[Setting category="Global" name="Only show Buffer Time when the Interface is Hidden?" description="Don't check both this and the below or the timer will never show."]
bool S_ShowOnlyWhenInterfaceHidden = false;

[Setting category="Global" name="Only show Buffer Time when the Interface is Visible?" description="Don't check both this and the above or the timer will never show."]
bool S_ShowOnlyWhenInterfaceVisible = false;

[Setting category="Global" name="Hide the Incredibly Useful MenuBar Item?" description="A MenuBar item will appear when Buffer Time is active. This menu contains many useful quick settings to change the behavior of Buffer Time (including disabling it for this collection of game modes)."]
bool S_HideIncrediblyUsefulMenuBarItem = false;



[Setting category="Global" name="Hotkey Enabled?" description="Enable a hotkey that toggles displaying Buffer Time."]
bool Setting_ShortcutKeyEnabled = false;

[Setting category="Global" name="Hotkey Choice" description="Toggles displaying Buffer Time if the above is enabled."]
VirtualKey Setting_ShortcutKey = VirtualKey::F5;



[Setting category="Buffer Time Display" name="Show Preview?" description="Shows a preview (works anywhere)"]
bool Setting_ShowPreview = false;

[Setting category="Buffer Time Display" name="Preview: Add Secondary Timer?" description="Adds a secondary timer to the preview if it's showing. Note: the timer will pause for 500 ms every 2000 ms."]
bool Setting_ShowSecondaryPreview = false;

[Setting category="Buffer Time Display" name="Plus for behind, Minus for ahead?" description="If true, when behind the timer will show a time like '+1.024', and '-1.024' when ahead. This is the minimum delta between players based on prior CPs. When this setting is false, the + and - signs are inverted, which shows the amount of buffer the player has (positive buffer being the number of seconds you can lose without being in a KO position)."]
bool Setting_SwapPlusMinus = true;

[Setting category="Buffer Time Display" name="Display Position" description="Origin: Top left. Values: Proportion of screen (range: 0-100%; default: (50, 87))" drag]
vec2 Setting_BufferDisplayPosition = vec2(50, 87);

[Setting category="Buffer Time Display" name="Font Choice"]
KoBufferUI::FontChoice Setting_Font = KoBufferUI::FontChoice::Oswald_Regular;

[Setting category="Buffer Time Display" name="Display Font Size" min="10" max="150"]
float Setting_BufferFontSize = 60 * Draw::GetHeight() / 1440;

[Setting category="Buffer Time Display" name="Enable Stroke"]
bool Setting_EnableStroke = true;

[Setting category="Buffer Time Display" name="Stroke Width" min="1.0" max="20.0"]
float Setting_StrokeWidth = 5.0;

[Setting category="Buffer Time Display" name="Stroke Alpha" description="FYI it's not really alpha -- but it's an approximation; not perfect." min="0.0" max="1.0"]
float Setting_StrokeAlpha = 1.0;

[Setting color category="Buffer Time Display" name="Color: Ahead within 1 CP"]
vec4 Col_AheadDefinite = vec4(0.000f, 0.788f, 0.103f, 1.000f);

[Setting color category="Buffer Time Display" name="Color: Behind within 1 CP"]
vec4 Col_BehindDefinite = vec4(0.942f, 0.502f, 0.000f, 1.000f);

[Setting color category="Buffer Time Display" name="Color: Far Ahead"]
vec4 Col_FarAhead = vec4(0.008f, 1.000f, 0.000f, 1.000f);

[Setting color category="Buffer Time Display" name="Color: Far Behind"]
vec4 Col_FarBehind = vec4(0.961f, 0.007f, 0.007f, 1.000f);

[Setting category="Buffer Time Display" name="Enable Buffer Time BG Color" description="Add a ((semi-)transparent) background box to the displayed Buffer Time."]
bool Setting_DrawBufferTimeBG = true;

[Setting color category="Buffer Time Display" name="Buffer Time BG Color" description="Background color of the timer if the above is enabled. (Transparency recommended.)"]
vec4 Setting_BufferTimeBGColor = vec4(0.000f, 0.000f, 0.000f, 0.631f);

[Setting category="Buffer Time Display" min=0.0 max=2.0 name="Secondary Buffer Time Scale" description="If a secondary timer is shown, how big should it be compared to the prioritized timer?"]
float S_SecondaryTimerScale = 0.5;



[Setting category="Final Time Display" name="Preview?" description="This will show a preview of what it will look like when your final time is shown."]
bool S_ShowFinalTime_Preview = false;

[Setting category="Final Time Display" name="Display Position" description="Origin: Top left. Values: Proportion of screen (range: 0-100%; default: (75, 25))" drag]
vec2 S_FT_DisplayPosition = vec2(75, 25);

[Setting category="Final Time Display" name="Font Choice"]
KoBufferUI::FontChoice S_FT_Font = KoBufferUI::FontChoice::Oswald_Regular;

[Setting category="Final Time Display" name="Font Size" min="10" max="250"]
float S_FT_FontSize = 120 * Draw::GetHeight() / 1440;

[Setting category="Final Time Display" name="Enable Stroke / Shadow"]
bool S_FT_EnableStroke = true;

[Setting category="Final Time Display" name="Shadow Instead of Stroke?" description="This replaces the stroke with a drop shadow. Stroke must be enabled, and the same settings work for both."]
bool S_FT_ReplaceStrokeWithShadow = true;

[Setting category="Final Time Display" name="Stroke Width" min="1.0" max="20.0"]
float S_FT_StrokeWidth = 7.5;

[Setting category="Final Time Display" name="Shadow Angle" min="0" max="360"]
float S_FT_ShadowAngle = 45;

[Setting color category="Final Time Display" name="Color: Text"]
vec4 Col_FT_Main = vec4(1, 1, 1, 1);

[Setting color category="Final Time Display" name="Color: Stroke"]
vec4 Col_FT_Stroke = vec4(0, 0, 0, 1);




[Setting category="KO / COTD KO" name="Show SAFE indicator when elimination is impossible?" description="If true, when enough players DNF or disconnect, the timer will change to the SAFE indicator (99.999 green). Note: Sometimes it is not possible to avoid showing this, e.g., if a player leaves early. Currently, the extent to which this setting is honored can be improved, but never perfectly."]
bool Setting_ShowSafeIndicatorEver = true;

[Setting category="KO / COTD KO" name="Show OUT indicator when elimination is inevitable?" description="If true, when you're guarenteed to be knocked out, the timer will change to the OUT indicator (99.999 red)."]
bool Setting_ShowOutIndicatorEver = true;

[Setting category="KO / COTD KO" name="Show SAFE indicator during No KO round?" description="If true, during the No KO round the timer will be visible as the SAFE indicator (99.999 green)."]
bool Setting_SafeIndicatorInNoKO = true;




const uint NbTaBufferTimeTypes = 6;
enum TaBufferTimeType {
    None, VsGhost, BestTimeOrPB, YourBestTime, YourPB, VsPlayer
}

[Setting category="TA / Solo" name="Prioritized Buffer Time" description="When two or more buffer times are available, which one has priority?"]
TaBufferTimeType S_TA_Priority1Type = TaBufferTimeType::YourBestTime;

[Setting category="TA / Solo" name="Secondary Buffer Time" description="When two or more buffer times are available, which one should be prioritized second?"]
TaBufferTimeType S_TA_Priority2Type = TaBufferTimeType::YourPB;

[Setting category="TA / Solo" name="Tertiary Buffer Time" description="When three buffer times are available, which one should be prioritized third? Note: it will not show up unless one of the high priority timers cannot be shown or is a duplicate."]
TaBufferTimeType S_TA_Priority3Type = TaBufferTimeType::VsGhost;

[Setting category="TA / Solo" name="Show two buffer times?" description="If true, when both of the above options are selected, a smaller buffer time will be shown beneath/above the first. (The larger one is the one with priority.)"]
bool S_TA_ShowTwoBufferTimes = true;

[Setting category="TA / Solo" name="Show during COTD Qualifier?" description="If true, the buffer time will be visible during COTD qualifier. Otherwise, it will be hidden."]
bool S_TA_ShowDuringCotdQuali = true;

[Setting category="TA / Solo" name="Hide when Spectating?" description="When spectating, the buffer time shown will be a comparison to your PB or the best ghost, depending on priority."]
bool S_TA_HideWhenSpectating = false;

[Setting category="TA / Solo" name="Update Timer Immediately?" description="By default, the buffer time will act as though you're in a live match -- you won't know a ghost hit a CP until it would if it were live. With this setting enabled, deltas will be shown instantly when you are leading and hit a new CP (this is roughly how checkpoint splits normally work)."]
bool S_TA_UpdateTimerImmediately = false;


array<TaBufferTimeType> _S_TA_PriorPriorities = {TaBufferTimeType::YourBestTime, TaBufferTimeType::YourPB, TaBufferTimeType::VsGhost};


void OnSettingsChanged_TA_EnsureCorrectPriority() {
    int[] currentPriorities = {S_TA_Priority1Type, S_TA_Priority2Type, S_TA_Priority3Type};
    uint changed = 0;
    for (uint i = 0; i < 3; i++) {
        if (currentPriorities[i] != _S_TA_PriorPriorities[i]) {
            changed = i; break;
        }
    }

    for (uint i = 0; i < 3; i++) {
        if (i != changed) {
            if (currentPriorities[changed] == _S_TA_PriorPriorities[i]) {
                // we swap
                currentPriorities[i] = _S_TA_PriorPriorities[changed];
                // still the same?
                if (currentPriorities[changed] == currentPriorities[i]) {
                    currentPriorities[i] = TaBufferTimeType::None;
                }
            }
        }
    }
    S_TA_Priority1Type = TaBufferTimeType(currentPriorities[0]);
    S_TA_Priority2Type = TaBufferTimeType(currentPriorities[1]);
    S_TA_Priority3Type = TaBufferTimeType(currentPriorities[2]);

    _S_TA_PriorPriorities.Resize(3);
    _S_TA_PriorPriorities[0] = S_TA_Priority1Type;
    _S_TA_PriorPriorities[1] = S_TA_Priority2Type;
    _S_TA_PriorPriorities[2] = S_TA_Priority3Type;
}




/* updates stuff */

// may as well let ppl view past updates if they want to again
[Setting category="Updates"]
bool S_News_Viewed_2022_11_15 = false;

[Setting category="Updates"]
bool S_News_Viewed_2022_11_18 = false;



/* debug stuff */


[Setting category="Debug Screens" name="KO: Show All Players' Deltas" description="When checked a window will appear (if the interface is on) that shows all deltas for the current game (regardless of whether it's KO or not)."]
bool S_ShowAllInfoDebug = false;

[Setting category="Debug Screens" name="Show TA State Debug" description="Shows which reference ghosts/times are used atm."]
bool S_ShowDebug_TA_State = false;



/* meta state, e.g., first load, wizard, etc */



#if DEV
[Setting category="Hidden"]
#elif FALSE
bool IDE_S_Meta_FirstLoad = true;
#else
[Setting hidden]
#endif
bool S_Meta_FirstLoad = true;

// What version were we when the user first installed the plugin
#if DEV
[Setting category="Hidden"]
#elif FALSE
string IDE_S_Meta_EarliestVersion;
#else
[Setting hidden]
#endif
string S_Meta_EarliestVersion;
