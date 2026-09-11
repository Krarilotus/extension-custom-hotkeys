# Keyboard navigation in the native Load dialog

Tab and Shift+Tab traverse eligible controls in the active single-player Load
dialog; Enter activates the highlighted control through native cursor hit testing.
This includes existing save rows, Load, Back, sort headers and available scroll
arrows. Empty rows, an unavailable Load button and scrollbar dragging are excluded.
The original mouse operation remains available. This is not quickload yet.

SHC1.41 modal9 must be the actual active composition with menu0xB97688 and
array0x601A88. Its original table has no editable field; Save10 does. Native text
owner state1/index4, other modal slots, focus, IME, session, authority and transition
checks remain mandatory. Only menu navigation actions gain the `game.load` context;
world actions, hotkey capture and Save text-field handling are not enabled there.

Geometry comes from the active input composition, as for Options. List length is
bounded to500, visible rows to16, and every sort mapping index to0..499. Selection,
scroll offset and native list mapping form the gesture identity. Changes cancel a
pending click before another entry can receive its release. The next frame rereads
the active controls and requires native hover before introducing a click edge.
The extension does not write selection indices or invoke Save/Load callbacks.

Original owners: Load row0x4948C0, buttons0x4943B0, sort headers0x492DE0.
The native button owner checks file existence and routes SP load through modal14
with operation31 and the existing session/load owner. The extension never calls
that progress callback or the simulation state loader directly.

392 component tests pass under Lua54 and LuaJIT, including owner/text/session
rejection, empty-list and scroll-edge filtering, and cancellation across list
changes. The native diagnostic below passed its bounded scope.

## Native evidence

PID26300 on9b7ff85,11 September2026: mouse started Castle Builder/A Mighty Oasis;
diagnostic F10 opened Load. F9 traversed Load, Back, the single hk row, Name,
Date and back to Load, skipping empty rows and unavailable scroll arrows. F8
activated the row normally, then the Load button at22:34:57.131. The native loader
restored the Nicaea hk save: mode2 became0, camera2772/1864 became1632/1376, and
group1 restored unit52/serial4535. No save file was overwritten.

Group recall in Load was rejected. After restoration, recall1 selected the archer
with native tribe1246; next-group cycling wrapped back to the single populated
group and retained count1/tribe1246/camera1632/1376. This tests a single populated
group; it does not establish multi-group ordering or command counts.

At22:34:57.164 the pending cursor gesture was cancelled in its release phase when
the native Load owner disappeared. After restoration, mouseButtons and resetPending
were0. Error log: header only. Exact executable/dependencies/config match
`docs/control-groups.md`. Task receipts: `load-26300-{open,restored,group,cycle}.json`,
`load-26300.log`, `load-26300-error.log`, `load-26300-build.json`.

The diagnostic bypasses physical scan bindings because this backend emits scan0.
This is not a Tab/Enter, held-key, keyboard-only, MP or replay/state-restore pass.
The game closed normally, absence was verified, and the desktop was released
at22:35:37 CEST (3m18s of the6m reservation). The baseline config was restored.
