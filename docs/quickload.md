# Quickload through the native Load controls

`game.quickload` defaults to Ctrl+L. It loads the dedicated `Custom Hotkeys Quick`
slot created by [quicksave](quicksave.md). Original L lord focus and Shift+L
lord cycling remain configurable replacements. Both quick actions reuse one
workflow, the existing input-frame callback, context resolver, navigation and
native cursor owner. There is no extra hook, serializer or session implementation.

The normal guarded Load opener creates modal9. The workflow reads the native
ordered file mapping, bounded to500 entries with1001-byte NUL-terminated names,
and requires exactly one case-insensitive match. It retains the mapping and
revalidates that mapping, target name, screen, session, focus generation, text
owner and native modal geometry before each gesture. Missing/ambiguous names or
changed lists cancel, leaving normal Load UI available. It never writes a list
index, invokes a raw Load callback or retries an uncertain native commit.

The native vertical scrollbar supplies15-row page steps (callback0x492BA0,
operation7 returns visible rows minus1). Smaller distances use native arrow
controls. Once visible, the native row0x4948C0 is selected, then Load button
0x4943B0/parameter2 is activated through the usual hit-tested cursor path.
The native MenuItem scrollbar computes hover only after a press; its pre-press
readiness uses the same read-only native rectangle hit test0x4680C0. No fabricated
hover flag or coordinate conversion is introduced. Paging is bounded, including
the500-entry case, with a900-frame failure limit. Idle workflow work is skipped.

Selection/scroll changes invalidate old cursor gestures; their owned edges are
cancelled before the next step. Each step must produce its expected native list
state. New typing, physical pointer takeover, focus/IME changes, covered controls
or unknown states cancel. Trigger repeat/up/character debt stays suppressed;
Control release alone does not cancel. Progress14/operation31 hands ownership
back to native loading, without claiming that a file operation succeeded.
Active multiplayer and Recorder remain gated by the existing integration contract.

## Native evidence,12 September2026

SHC1.41 SHA256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`,
UCP3.0.7-77c6a, UI1.0.1, LuaJIT1, cffi1, winProcHandler1 and graphics1.3.
Legacy hotkeys and Recorder inactive; isolated diagnostic config SHA256
`0df5b909572bc96a8209450bcfea6a995fcad4ffca2c7eb39003419c385baabe`.

- PID21676: mouse prepared Castle Builder/A Mighty Oasis. Diagnostic F11 accepted
  at00:13:45.250 and loaded the dedicated slot from a two-file native list.
  The owned cursor release cancelled at the Load transition. Gameplay returned;
  F10 then overwrote the same slot through native Save/overwrite at00:14:05.
- PID23416:40 task-created save copies made42 entries. F11 found dedicated index40
  off screen, paged offset0 ->15, used10 native down-arrow steps to25, selected
  visible row15 and submitted Load once. Step receipts span00:16:25.494 to
  00:16:26.169; native return to the saved Castle Builder session was observed.
  No frame failure; error log header only. All40 temporary copies were verified
  against their manifest and removed after exit, preserving both original saves.

Read-only samplers and exact staged-source hash manifests are in task receipts
`native-evidence/quickload-21676*` and `quickload-23416*`. Both games and samplers
were closed/finished, absence verified, baseline configuration restored and
slots released at00:14:24 and00:17:03 CEST. Each desktop slot used under2 minutes.

The injected F keys bypass physical scan lookup. These are native adapter checks,
not physical Ctrl+L/held-key or complete keyboard-only acceptance. Full native
command-count, text/focus, maximum-list performance, multiplayer and Recorder
replay/state-restore acceptance remain open. Component tests cover bounded list
planning, missing/duplicate/changed names and mapping, rejected gestures, timeout,
trigger debt and user takeover on both Lua5.4 and LuaJIT.

Native ownership findings are tracked upstream in [OpenSHC#229](https://github.com/sourcehold/OpenSHC/issues/229).
