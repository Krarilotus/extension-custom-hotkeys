# Legacy replacement audit

This is a source-backed development contract. The bindings below are proposed
defaults, not implemented or native-tested replacements. They must not be
advertised as available in the current component PR.

Reference executable: SHC 1.41, SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
Legacy audit: `caa50aba9fc85c5fc766c413b23085ddfbba4a79`, `port/o_keys.lua`.

| Action identity | Proposed default | Native behavior to preserve |
|---|---|---|
| camera.pan.up/left/down/right | W/A/S/D | Local held pan, bounded by the actual active gameplay screen; cleanup on release/focus/transition. |
| camera.focus.armory | Alt+A | Original A obtains the local player's armory building, saves the previous view and focuses its location. This does not open the armory panel. |
| menu.open.armory | Ctrl+A | Original Ctrl+A opens the status panel for that armory through 0x463310. Retain this existing route and make it configurable. |
| camera.return.armory | Shift+A | Original Shift+A returns to the saved view and clears it; it may close an active building panel. Preserve native validity checks. |
| camera.cycle.signposts | Alt+S | Original S cycles the eight native signpost building references and focuses their coordinates, skipping missing entries. Local camera action, not a construction/selection action. |
| unit.stance.defensive | Alt+W | Original W on the active unit panels queues defensive stance through 0x522BF0 -> GameSynchronyState::queueCommand(0x46). Never call the direct stance setter 0x522C20. |
| session.quicksave | Ctrl+S | Save through the normal SP save owner with the chosen quicksave name; do not patch the global text getter. |
| session.quickload | Ctrl+L | Load through the normal SP session owner. Native MP/replay eligibility must reject any unsupported SP shortcut. |

On the reference image, the WM_SYSKEYDOWN table routes Alt+A, Alt+S and Alt+W to
the original default branch; this is why they are candidates for the displaced
actions. Full profile conflict detection must still cover other extensions,
system/layout combinations and native modifier aliases. AltGr is text-owned.
Ctrl+Shift and other modifier combinations cannot be assumed unused simply
because the manual lists only an unmodified key.

Unmodified D has no action in the original WM_KEYDOWN table. Alt+D follows a
separate native debug-overlay route, observed in the isolated baseline. It is
not the map-description editor and must not be accidentally remapped as one.
Plain L's original local-player unit focus remains reachable; its modifier
variants still need complete coverage in the original-binding catalog.

The armory field resolves to GameStateStructures.playerDataArray[player].armory.id
at 0x115BF04 + player*0x39F4. The S array is
0x112B0B8 + 0x516D4 + 0x2918 = 0x117F0A4; its native writer at 0x456EF0
checks building type 0x34 (signpost), stores those IDs and their entrance data.
These native callers and field/enum matches substantiate the identities. Runtime
availability, exact outcomes and replacement keys remain acceptance work.

Legacy's quicksave/quickload implementation intercepts text-name lookups and
builds its own wrapper around save/load progress handling. Copying that code
would preserve its broad input coupling. The original SP save entry 0x495800
chooses action 0x20 or 0x2E; the distinct load entry 0x495840 chooses 0x1F.
These are discovery leads, not permission to bypass the session owner's normal
load selection, multiplayer coordination, authority or recorder lifecycle.

Legacy `o_keys.enabled` must be exactly false before activation. Do not patch
over it and do not call its unimplemented live disable. A restart with corrected
configuration is required. Disabling Custom Hotkeys must restore native input
forwarding; selecting Legacy again is an explicit clean-launch choice.

Literal AOB audit across Legacy ports also identified `o_gamespeed` at
0x4B4748/0x4B47C2. It changes speed handling, not the WASD branches. `o_fast_placing`
affects the native placement path at 0x445D8C and must be included in placement
equivalence tests. This is not evidence for disabling unrelated Legacy options;
complete the interaction audit against the final native adapter first.
