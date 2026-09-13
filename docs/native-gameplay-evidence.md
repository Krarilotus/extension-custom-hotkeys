# Gameplay adapter development evidence

11 September 2026, isolated SHC1.41/UCP3.0.7 process11376. Reference executable
SHA-256 `3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
Exact source/config receipts: task `native-evidence/world-adapter-11376*`.

Mouse navigation started Nicaea through ordinary campaign/mission screens.
Task-only F7 invoked the production settings action from live screen14/tab48:
the native editor opened, displaying Default and all16 current development
actions. Clicking Cancel returned to the live mission. No profile was saved.
This verifies gameplay settings entry/cancel through that native adapter; it
does not verify physical F12 or keyboard-only acceptance.

Task-only F6 target centering returned false without moving the cursor or
issuing an action. Inspection found that imported viewportX/Y/width/height are
map offsets and tile counts. The corrected adapter reads the pixel rectangle
written by setupViewport(0x4E66F0) at base+0x18B728. Its caller0x4E7770 passes
the current screen size, normally subtracting128 pixels of toolbar height.
The correction still needs a new native check; no targeting pass is claimed.

The settings test used orientation0. A later source correction recognizes native
orientations0,2,4,6 (0x4E5F5A and the rotation-key path). All-orientation native
placement/targeting acceptance remains pending.

Alt+F4 closed the test normally; PID absence was checked, the slot released at
17:05:18CEST, and the original isolated baseline configuration restored.

The earlier baseline process25996 established that native right-click deselects
the selected lord and that the owned-selection flag remains stale afterward.
The adapter therefore fingerprints selected count/lastID and the native bitset,
plus active building/unit IDs. It reads native placement, patrol, camera and zoom
state at each dispatch/gesture phase. Editor screens, text/modal ownership,
pause, incomplete transitions and unverified sessions reject gameplay dispatch.

Multiplayer is currently excluded by the new gameplay resolver. Recorder remains
a pre-activation conflict pending its owner's synchronous lifecycle API. Full
building/economy/unit action coverage, command counts and gameplay/replay
acceptance are still required.
