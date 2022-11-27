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
bool IsGPSActive() {
    auto gameScene = GetApp().GameScene;
    if (gameScene is null) return false;
    CSmPlayer@ currPlayer = VehicleState::GetViewingPlayer();
    if (currPlayer is null) return false;
    auto vis = VehicleState::GetVis(gameScene, currPlayer);
    if (vis is null) return false;
    auto playerPos = vis.AsyncState.Position;
    auto playerVector = vis.AsyncState.Dir;
    g_PlayerToCamera = playerPos - Camera::GetCurrentPosition();
    bool notDriving = Camera::IsBehind(playerPos + playerVector) || g_PlayerToCamera.LengthSquared() > MAX_CAMERA_DIST_SQ;
    // print("Dist: " + g_PlayerToCamera.Length() + ", and IsGPSActive: " + tostring(notDriving));
    return notDriving;
}
