[Setting category="Global" name="Show Buffer Time during TA / Campaign?"]
bool S_ShowBufferTimeInTA = true;

[Setting category="Global" name="Show Buffer Time during KO / COTD KO?"]
bool S_ShowBufferTimeInKO = true;



[Setting category="KO / COTD" name="Show SAFE indicator when elimination is imposible?" description="If true, when enough players DNF or disconnect, the timer will change to the SAFE indicator (99.999 green). Note: Sometimes it is not possible to avoid showing this, e.g., if a player leaves early. Currently, the extent to which this setting is honored can be improved, but never perfectly."]
bool Setting_ShowSafeIndicatorEver = true;

[Setting category="KO / COTD" name="Show OUT indicator when elimination is inevitable?" description="If true, when you're guarenteed to be knocked out, the timer will change to the OUT indicator (99.999 red)."]
bool Setting_ShowOutIndicatorEver = true;

[Setting category="KO / COTD" name="Show SAFE indicator during No KO round?" description="If true, during the No KO round the timer will be visible as the SAFE indicator (99.999 green)."]
bool Setting_SafeIndicatorInNoKO = true;




[Setting category="TA / Campaign" name="Show Compared to Best Loaded Ghost?" description="If true, a buffer time will be displayed relative to the best ghost that was loaded at any point since the map was loaded. (The ghost can be unloaded immediately if you want.)"]
bool S_TA_VsBestGhost = true;

[Setting category="TA / Campaign" name="Show Compared to Personal Best?" description="If true, a buffer time will be displayed relative to your PB ghost, or the best ghost that was loaded with your UserName. (The ghost does not need to be visible.)"]
bool S_TA_VsPB = true;

[Setting category="TA / Campaign" name="Show two buffer times?" description="If true, when both of the above options are selected, a smaller buffer time will be shown beneath/above the first. (The larger one is the one with priority.)"]
bool S_TA_ShowTwoBufferTimes = true;

enum TaBufferTimeType {
    BestGhost, PersonalBest
}

[Setting category="TA / Campaign" name="Prioritized Buffer Time" description="When two buffer times are available, which one has priority?"]
TaBufferTimeType S_TA_PrioritizedType = TaBufferTimeType::BestGhost;
