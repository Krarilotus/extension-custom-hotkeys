# Native world adapter evidence — 11 September 2026

This is bounded adapter evidence, not keyboard-only or multiplayer acceptance.
PID3580 ran the isolated Nicaea mission on SHC1.41 with executable SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
Dependencies and configuration match the preceding native gameplay evidence.
Legacy and Recorder were absent. The source/config manifest is retained at
`Roadmap/Investigations/Custom-Hotkeys/native-evidence/world-3580-build.json`.

The task-only F-key diagnostic bypasses physical binding lookup and invokes the
production adapters. Every logged diagnostic still had scan=0. It is excluded
from product code. Mouse input prepared the mission and selected the lord.

- Target center moved the visible cursor to native pixel (640,296). The actual
  viewport rectangle was (0,0,1280,592), confirming the corrected 0x233A300 fields.
- With the lord selected on screen14/tab61, defensive stance returned accepted.
  Current native tribe was1246, selected count1, selected-last57. The native
  defensive shield was visible. The adapter calls submission wrapper0x522BF0,
  which queues type0x46; no direct stance setter is called.
- Target center followed by one target confirm visibly moved the selected lord
  from the starting position to the center target through native mouse input.
  Native held mouse buttons were zero afterward; selection remained count1.
- Diagnostic pan-up set the native held flag to1 and cameraY changed1584→1337.
  Explicit diagnostic release returned that flag to0 (cameraY816). This verifies
  the local adapter, not a physical W key hold, focus-loss hold or arrow overlap.
- No Lua/input-frame error was logged. Alt+F4 closed PID3580 normally; process
  absence was checked. The desktop was released at17:30:24 CEST and the isolated
  baseline configuration restored.

Receipts: `world-3580-{start,center,stance,order,pan,release}.json`,
`world-3580.log`, `world-3580-error.log` in the task evidence directory.

No native queue-count instrumentation, duplicate-command proof, attack/building
placement, armory/signpost replacement, physical rebinding, minimum-resolution,
two-peer multiplayer or replay/state-restore pass is claimed by this run.
