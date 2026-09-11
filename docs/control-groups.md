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
panel: group selection/focus or building controls. Configurable actions are:

- `unit.group.recall.0` through `.9`: select a group, or focus it if its selection
  already matches the native selected set.
- `camera.group.0` through `.9`: focus its first eligible member without changing
  selection or issuing a simulation command.
- `unit.group.next` / `.previous`: cycle through up to ten group slots, skipping
  empty/ineligible groups. The cursor is only a local group number; no world
  positions or delayed commands are cached.

These additional actions start unbound, so choosing their keys does not silently
replace the context-dependent original number shortcuts.

Recall validates every one of the2500 native group records before calling native
selection (including entries after holes), bounds IDs before dereferencing, rejects
current-serial foreign ownership and requires an eligible living member. Native
selection retains its serial-mismatch pruning. Camera focus also checks the tile.
Native `isUnitShortcutAvailable(0x5360A0)` determines whether to focus an already
matching selection. Otherwise the original sequence is
`queueEscapeCommand(0x536C70)` then `makeSelectionBasedOnShortcut(0x535FD0)`.
The first queues category0x0F. The second rebuilds the local selection through
`createTribeFromSelectedUnits(0x535B00)`, which validates local player membership
and submits category0x10 through `queueCommand(0x489100)`. Neither command's
simulation execution routine is called by this extension. Two distinct native
commands in this sequence are expected; they are not duplicate activations.

After submission, the adapter preserves the original local selection-panel
transition from0x4B464B..0x4B4695: remember the prior build tab, select tab61,
call `switchToMenuView(14,0)`, and update its local interaction/render flags.
Pending extension cursor gestures are cancelled first. Shared context barriers
quarantine held keys if the selection/menu changes. OpenSHC command-selection
ownership and its branch remain unchanged.

Component tests cover native call order, group/member bounds, foreign ownership,
repeat suppression, text/selection/context changes and original-key conflicts.
Single-unit native assignment/transfer evidence follows. Native cycling and
complete keyboard-only, multiplayer and replay/state restore acceptance are pending. The module still rejects active MP and Recorder.

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

## Native recall and focus evidence

PID21016 on b866794, 11 September 2026, used the same isolated Nicaea setup.
F10 assigned archer52/serial4535 to group1. After mouse deselection, diagnostic
F11 recalled it: selection count returned from0 to1 and the panel changed from48
to61. The native tribe changed from1246 to1243; the camera stayed1789/1584.
A second F11 focused the matching selection at1632/1376 without changing tribe
or selected count. F11 in the Save name dialog was rejected; selection and
camera remained unchanged. The error log contains only its header.

Task receipts: `recall-21016-{assigned,deselected,recalled,focused,save-rejected}.json`,
`recall-21016.log`, `recall-21016-error.log`, `recall-21016-build.json`.
The executable, dependencies and config hash match the assignment run above.
The native Save button created task-local `hk.sav` (757523 bytes, SHA256
`c8326f155641249681b577952134850a8a2f4aee75bb82876ce72729327d3878`).
Reload validation is pending. Bulk text insertion did not enter a name; separate
h/k key presses did. Shift+F1 through the test backend did not open Save.

This is native adapter evidence, not physical binding or keyboard-only acceptance.
No group-cycle, command-count, multiplayer or replay claim follows. Alt+F4 closed
the game, process absence was verified, and the queue released at22:12:57 CEST;
the isolated baseline configuration was restored.
