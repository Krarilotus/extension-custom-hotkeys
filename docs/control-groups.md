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
