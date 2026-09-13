# Presets and grid controls (development)

The editor provides Game Default, Modern RTS and Grid. New installations start
with Game Default. Select a profile on the Profiles page, then Apply. New profile
copies the selected profile, including its reset baseline. Reset action/profile
restores that baseline; export/import preserves it. Names are stored independently
of game language; built-in names and grid action labels are localized.

| Behavior | Game Default | Modern RTS | Grid |
| --- | --- | --- | --- |
| Pan camera | Arrows | WASD; native arrows retained | Arrows |
| Stand ground / defensive / aggressive | Q / W / E | Q / Alt+W / E | Alt+Q / Alt+W / Alt+E |
| Signposts / armory | S / A | Alt+S / Alt+A | Alt+S / Alt+A |
| Show/hide interface | Tab | Ctrl+Tab | Ctrl+Tab |
| Next / previous menu control | Ctrl+PageDown / Ctrl+PageUp | Tab / Shift+Tab | Tab / Shift+Tab |
| Quicksave / quickload | Ctrl+S / Ctrl+L | Ctrl+S / Ctrl+L | Ctrl+S / Ctrl+L |
| Assign / select / focus group | Ctrl+number / number / number again | Same | Same |
| Assign / recall camera position | Shift+Alt+number / Ctrl+Alt+number | Same | Same |
| Pointer selection / orders | Native left/right | Left selects; right orders | Native left/right |
| Move / center / confirm / cancel target | Numpad 8/4/2/6 / 5 / Enter / Decimal | Same | Same |
| Focused dialog slider | Left / Right | Same | Same |
| Build categories | Individually assignable | Individually assignable | Q W E R T Y physical positions |
| Active panel command slots | Individually assignable | Individually assignable | A S D F G H, Z X C V B N physical positions |

Grid categories follow the native toolbar's left-to-right order: Castle,
Industry, Farms, Town, Weapons, Food. Slot keys follow the active supported
command buttons in visual row order. Vertically overlapping icon rectangles form
one band, read left to right, so shorter buildings do not jump ahead of taller
neighbors. Disabled controls retain their slot and
reject activation. Hidden/inactive controls are absent. The existing 107 audited
selectors include construction and engineer siege menus. Recruitment/economy
controls use active native panel membership and their actual handlers. Original
callbacks run once after input-frame revalidation, without moving the construction
cursor. There is no extra hook or idle grid polling. Slots are configurable
actions, alongside the individual building actions.

Grid displaces several original shortcuts. Their replacements use Alt plus the
same physical key: granary G, keep H, zoom Z, rotate X/C, lower buildings V,
barracks B, mercenary post N and tunnelers T. Original Ctrl building open and
Shift camera-return shortcuts remain available according to profile rules.
Game Default retains native modifier aliases when an action is still bound to
one of its original gestures. Explicit rebinding/unbinding suppresses those
aliases. Alias masks are compiled when applying a profile, not scanned on each
unassigned key press.

Bindings store Set-1 scan codes and E0, never localized letters or virtual-key
codes. The sixth category is physical scan21: Y on US, Z on German keyboards.
The lower-left grid slot is scan44: Z on US, Y on German. Windows supplies the
displayed key name. The geometry principle is informed by the official
[Age of Empires II grid/control-group guide](https://www.ageofempires.com/learn-to-play/match-goals-aoe2/).
This six-column adaptation uses SHC's own toolbar and command panels.

Profile document schema3 supports keyboard and mouse bindings and64 named profiles.
Schema1/2 imports/load preserve existing bindings, profile names and active
selection. Only explicitly versioned new actions may be absent; they become
unbound in old profiles. Missing old actions, unknown fields/actions and conflicts
still fail validation. The three preset copies are added under unique names,
without replacing a same-named user profile. Migration is saved only through the
normal Apply operation and alternating verified store. The storage envelope
schema remains1. Older extension builds do not understand the new payload.

## Pointer and bookmark behavior

Modern RTS uses left-click to select and right-click for contextual orders.
Shift+left adds to selection; Shift+right queues through native order handling.
Placement keeps left-confirm/right-cancel. Mouse buttons1-5 and modifiers are
assignable. The official
[Crusader DE manual](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/3024040/manuals/2483eddbccb05eec2676d6c8e80b7f7c5b0bb3e1/Stronghold_Crusader_Definitive_Edition_Manual_-_English_v1.01.pdf?t=1758638709)
is the reference for the requested modern pointer behavior.

Ctrl+number assigns the selected owned building, including mercenary posts, or
the native unit group. Recalls validate building identity and ownership. Groups
and camera bookmarks clear on leaving/loading the world and available Recorder
restore notifications; they are local input state, not saved simulation data.
Numpad target movement is24 pixels, or one pixel with Shift.

[0.1.6 evidence](features-0.1.6.md) records native mouse capture, Modern selection,
building/camera recall, keyboard placement/recruitment/trading and a completed
Recorder/Automarket playback. Drag/queued orders, the full text/held matrix,
state restore and other documented checks remain outstanding. Two-PC testing is
manual and does not restrict tester access.

## Native development evidence, 12 September

Frozen11ba28f ZIP, SHA25636754a53145785061e71647477857371fb4dd04ff1f95412f85f74909c6c5d7a,
135982bytes; two identical builds. SHC1.41 reference, UCP3.0.7-77c6a/UI1.0.1,
English game/German Windows labels, Legacy/Recorder inactive. PID31580,
desktop slot03:31:13-03:37:23 CEST, closed normally/absence verified and released.

F12 opened211 actions with Game Default. All three profiles were selectable.
The first Apply actually saved Modern RTS: an attempted previous-profile mouse
click had not changed the displayed selection. The later in-game selection and
Apply saved Grid, verified in the display and persisted payload. W panned under
Modern RTS; after Grid Apply it used the category path. Shift+F2 reached native
Load and Ctrl+L restored the dedicated quicksave through production input.

Industry was unavailable before the starting keep/granary prerequisites, also
when clicked with the mouse. Grid Q opened the keep choices; A selected the keep
and then the startup granary. Mouse clicks placed both for preparation. After
that, W opened Industry. S selected the ox tether, exposing an incorrect sort by
icon top edge. The rectangle-band ordering change follows this failed check;
its native retest remains required. No grid woodcutter pass is claimed.

Error log contained headers only. No save was overwritten. Actual scan-code
receipts: task native-evidence/presets-31580*. No command-count, keyboard-only
placement, restart, migration, siege-panel or multiplayer/replay pass is inferred.
