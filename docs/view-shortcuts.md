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

V and Ctrl+Down lower buildings through `0x4F6FD0` and separately held native
flags. Their replacement is not implemented yet: these bindings remain native
and cannot be displaced by a custom assignment. They are not incorrectly
advertised as pan-down. Native restore callers `0x434509` and `0x443A63` require
the actual mouse/keyboard hold state; do not emulate lowering with an unowned
sticky flag. This is a remaining view-workflow requirement.

Component checks cover orientation wrap, both zoom states, busy/right-held and
pending-rotation rejection, text/modal/replay/authority guards, and the corrected
native conflicts. Native transformation and orientation-target acceptance remain
pending. This document does not establish a complete original/layout inventory.
