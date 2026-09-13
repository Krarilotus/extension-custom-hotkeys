# Save and Load dialog shortcuts

`game.save.open` defaults to Shift+F1; `game.load.open` to Shift+F2. Their native
Ctrl+Shift aliases participate in original-binding conflict detection. These
actions open the ordinary native dialogs; they do not save/load immediately.
The [quick actions](quickload.md) now build on these native dialog owners.

Reference SHC1.41 SHA256:
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
Original WndProc branches `0x4B3223`/`0x4B32B6` call
`MenuTextInputState::loadOrSaveGame(0x4968A0,this=0x11265A8,10/9)`.
The extension uses that boundary after rechecking the shared live screen,
modal, text, focus, selection, authority and session context. Additional native
mode, scenario restriction and local-player death checks apply. Mode1/4/6 and
unverified modes are rejected. Synchrony0/99 is allowed; Save in mode99 also
requires the native host flag1. The Load99 scenario check is conservatively
stricter than the original branch. Active multiplayer and Recorder remain gated.

The native owner discovers saves through ResourceManager, initializes list
selection, activates modal9/10 through `0x4916C0`, and gives Save text index2 to
UserTextHandler. The extension neither writes its list/state fields nor invokes
raw Save/Load button callbacks. The multiplayer branch of this owner can queue
category0x32 while listing load candidates; it must not become reachable by
removing the current session gate without coordinated multiplayer acceptance.

Pending extension cursor gestures are cancelled before opening. On entering the
text modal, ordinary text remains native and extension world actions resolve to
no eligible context. Component tests exercise one owner call per activation,
the mode/session restrictions, changed-context rejection and original conflicts.
Native quicksave/quickload diagnostics are recorded in [quickload](quickload.md).

Native adapter check on 11 September 2026, PID6852, source8a34462: diagnostic
F10 invoked `game.save.open` once at21:37:05.791 and opened Save/modal10 with text
index2. F11 while that field owned input was rejected with no eligible context.
After mouse Back, diagnostic F11 invoked `game.load.open` once at21:37:43.656
and opened Load/modal9. The empty load list had its native Load button disabled.
No save was written or loaded. The error log contains only its header.
Evidence is in workspace `native-evidence/session-6852*`, with configuration SHA256
`0df5b909572bc96a8209450bcfea6a995fcad4ffca2c7eb39003419c385baabe`.
The game exited normally and process absence was verified before releasing the
desktop at21:38:13 CEST; the isolated baseline configuration was restored.

These checks used mouse fixture setup and diagnostic adapter calls because the
computer-use backend supplies scan0. They prove the dialog boundary and text
rejection in that run, not physical binding, keyboard-only, command-count,
quicksave/quickload, multiplayer or replay acceptance.
