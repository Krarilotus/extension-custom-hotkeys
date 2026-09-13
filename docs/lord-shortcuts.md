# Lord focus shortcuts

`camera.focus.lord` defaults to L. `camera.cycle.lords` defaults to Shift+L.
They move the local camera through native `focusOnTile(0x4E5E20)` without
selecting units or issuing movement commands. Ctrl+L is an original focus alias
and participates in conflict validation, so a future quickload binding cannot
displace lord focus without an assigned replacement. Ctrl+Shift+L is a cycle alias.

Reference SHC1.41 SHA256:
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
WndProc `0x4B3D83` rejects repeated input, inactive gameplay and modals. Without
Shift it reads the local player's lord reference at `0x115DFF0+player*0x39F4`;
checks unit type55, owner and state2; then focuses its native tile. The extension
also bounds unit IDs and tiles, rejecting missing/reused/dead/foreign references.

With Shift, `0x4B3E19` cycles the native local index at `0xB39348` through1..8,
advancing it before testing each player. It calls `0x5377F0` on UnitsState
`0x1387F38` and stops after at most eight attempts. That native lookup checks
lord type, owner, state2 and its exclusion field. The extension uses the same
lookup, validates its returned reference and bounds the native unit count before
calling it. It does not invent a separate list of lords or world positions.

The common actual-screen/text/modal/focus/session/authority/transition gate
applies before these local actions. Component checks cover focus, invalid
references, cycle wrap, empty/dead cycles and text-context rejection. Native
lord-focus/cycle acceptance is still pending; this is not quickload delivery.
