# Control groups

`unit.group.assign.0` through `.9` assign the current owned unit selection to
the corresponding native group. Defaults are Ctrl+0 through Ctrl+9. Each action
is configurable; original Ctrl+Shift aliases participate in conflict detection.
One fresh press performs one assignment; repeats and transition-held keys do not.

The SHC1.41 original branch at `0x4B438F..0x4B4417` calls
`clearTribeHotKey(0x459BB0)` then `assignSelectionToKey(0x459C10)`, both thiscall
with owner `0x112B0B8`. The extension uses exactly that order. Native assignment
stores unit IDs with identity serials, skips inactive units and lords, and removes
assigned members from other groups. It does not submit a simulation command.
Reference executable SHA256:
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.

Dispatch requires the shared live SP, focus, text, modal, session and authority
context, screen14 with active unit panel61/62, a nonempty owned selection and
tribe1..1249 belonging to the local player. Before either native write, the
adapter bounds the tribe member count and validates every native member ID and
owner. A malformed group cannot erase the previous assignment. These extra
checks are deliberately stricter than the original keyboard branch.

Unmodified and Shift number keys are still forwarded to the original game and
protected against reassignment. Their original meaning depends on the active
panel: group selection/focus or building controls. Configurable group recall and
cycling remain required implementation work. The recall path includes
`queueEscapeCommand(0x536C70)`, `makeSelectionBasedOnShortcut(0x535FD0)` and native
selection UI transitions; substituting a direct selection-bit write is unsafe.
OpenSHC command-selection ownership remains separate and unchanged.

Component tests cover native call order, group/member bounds, foreign ownership,
repeat suppression, text/selection/context changes and original-key conflicts.
Native assignment, keyboard-only recall/cycling, multiplayer and replay/state
restore acceptance are pending. The module still rejects active MP and Recorder.

## Native assignment evidence

PID25128 on5570dc4,11 September2026, used the original Nicaea campaign fixture.
Mouse setup selected one archer: unit52, tribe1246, screen14/tab61, player1,
owned-selection flag1. Both groups1/2 initially contained only -1 in the sampled
first four entries. Diagnostic F10 called assignment1 at21:56:52.223; group1
then contained unit52/serial4535. F11 called assignment2 at21:57:06.369; group1
returned to -1 and group2 contained that same unit/serial. Other sampled entries
remained -1. Selection count1, camera1789/1584, orientation0, zoom0 and all four
pan flags0 were unchanged. Both adapter calls returned true without frame failure;
the error log contains only its header.

SHC1.41/UCP3.0.7-77c6a, UI1.0.1, LuaJIT1.0.0, cffi1.0.0,
winProcHandler1.0.0 and graphicsApiReplacer1.3.0; Legacy/Recorder inactive.
Configuration SHA256:
`0df5b909572bc96a8209450bcfea6a995fcad4ffca2c7eb39003419c385baabe`.
Task receipts: `native-evidence/groups-25128-{before,one,two}.json`,
`groups-25128.log`, `groups-25128-error.log`, `groups-25128-build.json`.
Alt+F4 closed the game; process absence was verified and the desktop released
at21:57:22 CEST to Interface. The isolated baseline configuration was restored.

This passes the single-unit native assignment/transfer diagnostic. The attempted
initial drag did not select troops; a mouse click was needed. The planned
text-dialog check was not performed before cleanup. Physical bindings/holds,
keyboard-only setup, multi-unit/lord exclusion/dead-member cases, command counts,
multiplayer and replay are not established by this run.
