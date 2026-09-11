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

390 component tests pass under Lua54 and LuaJIT, including owner/text/session
rejection, empty-list and scroll-edge filtering, and cancellation across list
changes. Native Load navigation and saved-fixture reload are pending.
