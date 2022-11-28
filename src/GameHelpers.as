// furthest observed camera distance while driving: 10.8333
// this was on "Formula Surf"; upside down the camera will drift to a dist of 10.1139
// set to 16**2 for a little bit extra space
const float MAX_CAMERA_DIST_SQ = 16**2;

vec3 g_PlayerToCamera;

// detect when GPS is being watched by looking at player's position vs camera position.
// limitations:
// - assumes UISequence is Playging
// - will trigger when spectating a player and they go thru the finish
// - will trigger in freecam mode
// - bug: sometimes Camera::GetCurrentPosition is static and wrong
bool IsGPSActive() {
    auto gameScene = GetApp().GameScene;
    if (gameScene is null) return false;
    CSmPlayer@ currPlayer = VehicleState::GetViewingPlayer();
    if (currPlayer is null) return false;
    auto vis = VehicleState::GetVis(gameScene, currPlayer);
    if (vis is null) return false;
    auto playerPos = vis.AsyncState.Position;
    // auto playerVector = vis.AsyncState.Dir;
    auto camPos = Camera::GetCurrentPosition();
    // sometimes campos is bugged; got coords (0, 1, -8.5).
    if (camPos.LengthSquared() < 100) return false;
    g_PlayerToCamera = playerPos - camPos;
    // Camera::IsBehind(playerPos + playerVector) ||
    bool notDriving = g_PlayerToCamera.LengthSquared() > MAX_CAMERA_DIST_SQ;
    // print("Dist: " + g_PlayerToCamera.Length() + ", and IsGPSActive: " + tostring(notDriving));
    return notDriving;
}

bool IsPlayerStationary() {
    auto gameScene = GetApp().GameScene;
    if (gameScene is null) return true;
    CSmPlayer@ currPlayer = VehicleState::GetViewingPlayer();
    if (currPlayer is null) return true;
    auto vis = VehicleState::GetVis(gameScene, currPlayer);
    if (vis is null) return true;
    return vis.AsyncState.WorldVel.LengthSquared() < 0.1;
}
