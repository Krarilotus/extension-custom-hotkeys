# View shortcuts and pending rotation

Development defaults: X rotates left, C rotates right, Z toggles zoom. Each is
configurable and invokes the original local view handler once per fresh press.
Plain/Shift arrows retain native panning. Ctrl+Left/Right/Up retain their native
rotation/zoom alternatives when unassigned; reassigning one requires a configured
replacement for its actual view action, not a pan action.

SHC1.41 reference SHA256:
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
The X branch `0x4B4191` adds2 modulo8 to the current orientation; C at
`0x4B41E2` adds6. Both call `0x4F70E0(this=0x1A93208,orientation)` after
checking the game screen, modal and native right-button state. That method
queues a local orientation request at `0x1FE7AA8`. The extension never calls
the deeper map-rotation implementation at `0x501B90`.

`0x512920` consumes orientation requests below8 through that native method and
resets the request to8. All extension world dispatch now requires that idle
sentinel. A pending rotation therefore cancels gestures before a stale target
can be confirmed. The completed orientation remains part of context identity.

Z at `0x4B4275` rejects repeated keydown, calls
`0x4E7770(this=0x21AEBD8,!zoom)`, then marks native render surfaces dirty
(`0xF983F8=2`, `0xB48EE4=1`). The extension follows this local boundary and
preserves native viewport setup and bounds. It cancels its pending cursor gesture
before a view operation. Text, modal, focus, session and authority checks apply;
MP and replay remain unavailable.

Ctrl+arrows use separate original branches at `0x4B2E50`/`0x4B2EDD` (rotation),
`0x4B2FD7` (zoom), and `0x4B2F62` (lowering). Ctrl+Up also falls through to the
original pan-up flag. Forwarded native input retains that behavior; the semantic
zoom action follows the distinct Z branch. Original X/C/Z modifier aliases are
included in conflict detection.

`view.lower-buildings` now defaults to held V. Original V modifier aliases and
Ctrl+Down remain native alternatives; reassigning either requires an assigned
lowering replacement. The extension calls the original0x4F6FD0 with3 once on
activation, maintains only its local V input flag and releases through the same
native handler with4 when no valid native mouse/keyboard hold remains. It never
implements a new map transformation or writes simulation state directly.

The existing OpenSHC `Input/ModifierKeyState/updateCtrlShiftAltKeyStateMemory.cpp`
provided the missing release owner. Assembly0x468A20 confirms that GetAsyncKeyState
for V clears offset0x14 (F224FC) when released; Down clears offset0x10 (F224F8).
WinMain0x57C2D8 calls that poll before the existing native input-frame site at
0x57C310 ->0x468100. The extension reasserts its rebound hold at that existing
callback, after polling and before native input. No additional hook is installed.
It performs one flag write per active hold frame; lowering itself is not called
repeatedly. Idle work is skipped, and camera/lowering share one context refresh.

Release preserves a separately forwarded V or Ctrl+Down/right-mouse hold only
while the current native world still owns it. Quarantined/consumed keys or stale
raw flags cannot retain the extension's lowering after a focus/modal transition.
All held gestures are revoked before any native cancellation callback, removing
table-order-dependent preservation of an old key. The extension's own V flag is
cleared even if the native ownership proof fails. Native handoff/physical key
acceptance remains separate from these component guarantees.

Native diagnostic PID5756 on12 September2026 loaded the prepared Nicaea hk save.
Mouse preparation used Castle Builder, normal Load and the minimap to show the
castle. F10 started the production lowering adapter; walls/tower visibly lowered,
VHold=1 and current lowered mode3. F2 release restored the visible tower/walls,
VHold=0/current mode4. A second lower then F11 Load opened modal9 and restored
VHold=0/mode4. F10 was rejected while Load remained active; no frame failure,
error header only. Config/executable match docs/quickload.md. Task receipts are
`native-evidence/lowering-5756*`; static ordering proof is
`ModifierKeyState-lowering-lifetime.asm.txt`. Game5756 closed normally, process
absence verified, baseline restored and desktop released00:39:58CEST (2m36s of5m),
handing the slot to the waiting aic-tactics worker. No save was overwritten.
After this native run, the release path was hardened to clear its owned flag
before an ownership-probe error; that fault-injection case has component coverage
and was not fault-injected in the native process.
These diagnostic F keys bypass physical lookup and do not establish physical V,
rebound key release, mixed mouse/key holds, keyboard-only, MP or replay acceptance.

Component checks cover orientation wrap, both zoom states, busy/right-held and
pending-rotation rejection, text/modal/replay/authority guards, and the corrected
native conflicts. In the isolated SHC1.41/UCP3.0.7 diagnostic PID20256,
rotation changed0 to2 and zoom0 to1 with visible native transformations;
pending rotation returned to8 and all four pan hold flags stayed0. Receipts
`view-20256-build.json`, `view-20256.log` and the before/rotated/zoom samples
are under the workspace's Custom-Hotkeys/native-evidence directory. That build
used f6a9c2d production code with task-only F-key calls because the backend
supplies scan0. These are native adapter checks, not physical-binding or
keyboard-only acceptance. Orientation-target acceptance remains pending.
This document does not establish a complete original/layout inventory.
