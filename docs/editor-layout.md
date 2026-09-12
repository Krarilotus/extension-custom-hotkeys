# Binding overview

The 760×552 native dialog shows 16 rows instead of six. Native font19 provides
16-pixel line spacing in 20-pixel rows; font17 gives a smaller title. Action and
Key are separate columns. The original Save/Load table renderer4692E0 supplies
striped red rows and selection. The UI owner's renderButtonBackground/463A90
supplies normal SHC buttons, including keyboard-focus highlighting. Borders read
the native palette rather than assuming a display pixel format. Native font measurement/clipping
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

The user requested native button text placement after observing top-aligned
captions. Original492B46 uses a30px button, font18, y+7 and TextManager alignment1
at x+width/2. The editor now uses those same values and native centering. Input
fields and table columns retain their own alignment. PID24132 compared this
directly with original Load/Back buttons and verified both editor pages.

That gameplay check also caught missing button/table textures: the editor forced
texture target0, which only worked on the main menu.18ca42f preserves the native
menu renderer's target; basic buttons use native target-1 selection and restore.
PID16012 tested the frozen18ca42f ZIP after starting A Mighty Oasis, opened F12,
and verified the corrected red rows, selected row and centered button captions
on both gameplay pages. No Lua error; no profile Apply or world save. Closed
normally and released the desktop04:18:04 CEST (2m26s of4m).

Screenshots are original window captures, without compositing or recoloring:
[gameplay editor](images/hotkeys-ingame.jpg),
[gameplay profiles](images/hotkeys-profiles-ingame.jpg),
[main-menu editor](images/hotkeys-menu.jpg),
[original Load/Back reference](images/native-button-reference.jpg).
These bounded checks do not establish the complete keyboard-only route,
minimum resolution, all languages, multiplayer or replay acceptance.

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

The user rejected the custom olive palette in the later11ba28f package preview.
It has been replaced with the original SHC table/button draw primitives and the
native modal's own framed, dimmed background. No new graphics are bundled. This
styling revision passed a new native visual check; PID22404/31580 above show
the superseded palette.

PID31988 loaded frozen10a6792 ZIP (137996bytes, SHA256
c6998f3a0853fc17865573eabdedcbb96578bb9f51b4b981bf07c0f624841bd7),
with the same reference/dependencies and1280x720 English/German-key environment.
F12 opened the16-row editor; the Grid profile saved in PID31580 was active after
restart. Native red row stripes, selected/hovered rows and normal SHC buttons
rendered on both pages. End reached211/211, showing12 grid slots; physical scan44
displayed German Y as expected. Cancel returned normally without Apply. Error log
had headers only. Closed/absence verified/released03:45:25 CEST (1m36s of4m).
Receipts: task native-evidence/skin-31988*. This checks the new skin and profile
restart, not the outstanding grid geometry/complete gameplay acceptance.
