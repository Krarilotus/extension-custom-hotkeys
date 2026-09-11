# Legacy replacement audit

This is a source-backed development contract. Pan, armory/signpost and stance
adapters are implemented with component coverage. Native PID3580 verified a
diagnostic pan/release and stance submission; physical WASD and the armory/
signpost routes still need native acceptance. Quicksave/load remain pending.
The catalog is incomplete and must not yet be distributed as a finished module.

Reference executable: SHC 1.41, SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
Legacy audit: `caa50aba9fc85c5fc766c413b23085ddfbba4a79`, `port/o_keys.lua`.

| Action identity | Development default | Native behavior to preserve |
|---|---|---|
| camera.pan.up/left/down/right | W/A/S/D | Local held pan, bounded by the actual active gameplay screen; cleanup on release/focus/transition. |
| menu.focus.armory | Alt+A | Original A obtains the local player's armory, saves the previous view, focuses its location **and opens its status panel**. The tail branch 0x4B418C -> 0x4B3B12 -> 0x4B3A35 reaches the native status opener at 0x4B3A45. |
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
These native callers and field/enum matches substantiate the identities. Armory
adapters reject missing, reused or foreign building references. Stance requires
the actual active unit panel and an owned, nonempty native selection. Signpost
cycling is bounded to eight native references. See native-world-actions-evidence.md
for the exact limited native outcomes.

Unassigned original arrow keys retain native forwarding as a familiar alternative
to WASD. Assigning an arrow to another custom action still requires an assigned
pan replacement. An extension pan releases only its own hold and preserves an
eligible forwarded arrow gesture; all owned holds stop on context/focus changes.
Physical arrow/keypad overlap still needs native acceptance.

The current original-binding table covers the audited A/S/Q/W/E and E0-arrow
branches for the reference letter positions. Complete layout-dependent virtual
key mapping, other original shortcuts and numpad aliases are still required
before distributing defaults; this table is not a claim of AZERTY compatibility.

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
