# Native building adapter development check

11 September 2026, isolated SHC 1.41 process 25200, exact executable SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
UCP 3.0.7, UI 1.0.1, graphicsApiReplacer 1.3.0; Legacy and Recorder absent.
Source hashes/configuration are in the task's `build-25200-build.json` receipt.
This run predates the editor text layout and interaction-mode identity changes.

Mouse setup entered Castle Builder, A Mighty Oasis. A task-only diagnostic
invoked production adapters directly because the automation key backend supplies
scan code zero. This is not configurable-key or keyboard-only acceptance.

- A woodcutter selector was rejected while the active panel was Keeps (tab13).
- Mouse-selected Manor House keep: center/confirm reached native validation but
  failed on obstructed terrain. Placement mode 60 remained active. The keep was
  then placed with the mouse as setup, not through the keyboard adapter.
- Mouse-selected granary: center/confirm visibly placed the granary, reducing
  wood from50 to45 and unlocking normal building menus. This is a positive
  native placement result after mouse selection.
- The Industry selector queued a gesture at (313,702), but the actual tab
  remained10 and the subsequent woodcutter selector was rejected. Queuing is
  not successful activation. This failure remains under investigation.
- The editor opened over live Castle Builder with134 listed actions and native
  code page1252. No profile changes were saved. No input-frame error was logged.

The slot expired before cleanup. Input stopped, the slot was released, and a
new FIFO cleanup slot was requested. The remaining game prevented other native
single-instance launches until cleanup. PID25200 was closed normally with
Alt+F4, absence verified, and the cleanup slot released at18:00:14 CEST. The
isolated baseline configuration was restored. Future runs reserve explicit
cleanup time and stop new checks by minute4.5 of a6-minute slot.

Logs and context receipts: `build-25200.log`, `build-25200-error.log`,
`build-25200-{start,keep,woodcutter}.json` under the task evidence directory.
Native command counts, duplicate-command proof, repeat/rotation/cancel,
keyboard-only workflows, multiplayer and replay acceptance remain pending.

Follow-up PID29652 used Nicaea, where the initial native building panel is tab48
and Industry is unavailable. The selector correctly rejected before queuing,
with zero held mouse buttons. That is a second negative control, not a retest of
the Castle Builder failure. Both unit interaction fields read0 in that state.
No cancellation trace occurred because no gesture was queued. The next positive
retest requires a native Castle Builder fixture with a keep and granary already
placed. See `layout-29652-world.json` for exact context.

PID23708 reproduced the Castle Builder failure with keep and granary placed.
Industry queued at (313,702), then cancelled in the aim phase 11ms later:
the input coordinates were still (639,296), the previous world position.
The context had not changed, no button was held, and no click edge had begun.
This identified an asynchronous cursor acknowledgement problem, rather than
permission to relax screen or native hover checks. The game was closed normally,
absence verified and the desktop released at18:32:23 CEST. Exact receipts are
`category-23708{,-error}.log`, `category-23708-{build,failed}.json`.

The fix waits for the normal WM_MOUSEMOVE acknowledgement before the aim frame,
bounded to eight input callbacks. Context, native control and physical takeover
checks remain active throughout; timeout cancels without a click. Component
tests cover delayed old coordinates, repeated identical movement, timeout and
text/state/physical cancellation.

Retest PID9476: on11 September at18:53 CEST, Industry opened from Castle Builder
tab10 to tab20. The woodcutter selector then selected placement mode51. Both
used production native cursor/menu adapters; no raw control callback was called.
The task-only F10/F11 diagnostics bypassed physical key lookup, and mouse input
prepared the keep and granary. This is an adapter pass, not keyboard-only,
command-count or packaged-module acceptance. The camera also visibly changed
position during the Industry test; its cause remains to be isolated against a
native mouse baseline and must not be silently counted as expected behavior.

Each control's native press changed panel/targeting state; the next input callback
cancelled the owned gesture in its release phase. The final sampler verified
zero held mouse buttons, zero camera hold flags, tab20 and placement51. The
game exited normally, absence was verified and the desktop released18:54:29.
The baseline configuration was restored. Receipts are `cursor-9476{,-error}.log`,
`cursor-9476-{build,woodcutter}.json`. The staged catalog had134 actions and
predated the building panel/toolbar additions; its per-file hashes identify the
tested code, including the acknowledgement fix.
