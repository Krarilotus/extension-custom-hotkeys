# Binding overview

The 760×552 native dialog shows 16 rows instead of six. Native font19 provides
16-pixel line spacing in 20-pixel rows; font17 gives a smaller title. Action and
Key are separate columns. Alternating rows and a selection background separate
the table from bordered buttons and key fields. Native font measurement/clipping
and layout-sensitive key labels remain shared with the previous editor.

Click a binding row or press Enter on the selected row to capture a key. Delete
clears a focused list row. Arrow keys, Page Up/Down and Home/End navigate; Tab
traverses visible controls. The Swap button appears only after a conflict.
Starting a new capture clears the previous conflict message.

Profile selection, creation, import/export and profile reset live on a separate
page reached through the Profile button. Switching pages preserves the draft
and uses the original Menu constructor with two preallocated/pinned item tables;
the existing modal/menu identity is unchanged. Hidden-page controls and empty
rows reject activation. Apply/Cancel retain their existing persistence semantics.

The vertical scrollbar reuses original MenuItem type6, its wheel/track/drag
handling and renderer492C60. Its callback implements the verified original
492BA0 protocol: query1, set2/3, current4, decrement5, increment6, page size7.
Only owned, focused, non-text/non-IME editor actions may change the offset.
Capture suspends scrolling. Bounds are recomputed for filtered lists; selection
stays visible. There is no extra input/frame hook or custom mouse-drag loop.
The native renderer reads current ButtonState and supplied scrollbar geometry;
it does not read the Save/Load list. Faithful original source is unchanged.

## Native evidence — 12 September 2026

SHC1.41 SHA256 `3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`,
UCP3.0.7-77c6a, UI1.0.1, LuaJIT1, cffi1, winProcHandler1, graphics1.3.
English game text and German Windows key names, 1280×720 game rendering.
Legacy/Recorder inactive. Task diagnostic staged production sources with an
exact file-hash receipt; these checks used real scan-code bindings and mouse UI,
not its F-key action-dispatch diagnostics.

PID4500 caught an array/value access error before the dialog opened. Fixed by
using the UI owner's `menu` value instead of reading fields on its `Menu[1]`
pointer array. A regression models that distinction. Closed normally and released
03:09:38 CEST; failed preview is not acceptance.

PID22404, slot03:10:16–03:13:19 CEST:

- F12 opened the redesigned 199-action editor with all16 rows readable.
- Wheel moved first/selected row1→2. A track press paged17→32 by15 rows.
- The automated drag produced a page step2→17. Actual thumb dragging is **not
  verified** by this result and remains a native acceptance item.
- Profile management and return preserved the list offset; bindings were absent
  from the profile page.
- Clicking Select group7 entered capture. F12 produced the expected conflict
  with Open hotkey settings and exposed Swap. Another capture accepted Ctrl+F12
  and displayed that draft binding. Cancel closed without Apply.
- End reached199/199 with scrollbar at the bottom; Home returned1/199/top.
- Error log had headers only. Game closed normally, absence verified, baseline
  configuration restored and desktop released.

Receipts under the task's `native-evidence/`: `dense-4500*`, `dense-22404*`.
The later message-reset refinement is component-tested, not rerun natively.
Minimum resolution, other native languages, complete profile persistence and
full gameplay/multiplayer/replay acceptance remain outstanding.
