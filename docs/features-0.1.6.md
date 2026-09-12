# Expanded controls: implementation and acceptance

Candidate 0.1.6 adds mouse-button bindings, building control groups, ten local
camera bookmarks, default keyboard targeting, and active recruitment/economy
grid controls. These changes are undergoing native acceptance; component tests
do not establish native correctness. Multiplayer remains open to manual testers.

Ctrl+number assigns the selected owned building or the native unit group.
A number recalls it; repeating the number focuses it. Alt+number focuses a
group directly. Building references include the native identity serial and are
discarded when the building is destroyed, replaced or no longer owned.
Shift+Alt+number stores a camera position; Ctrl+Alt+number recalls it. These local
bookmarks are cleared on leaving the world, entering Load, or an available
Recorder restore notification; they are not simulation/save data.

Numpad 8/4/2/6 moves the native target by 24 pixels, Shift reduces this to one
pixel, 5 centers it, Enter confirms, and Decimal cancels. The number-row group
keys and extended navigation keys retain separate physical identities.

Mouse bindings support left, right, middle and both side buttons with modifiers.
Modern RTS separates selection and contextual orders; Classic and Grid retain
original primary/secondary clicks. The same winProcHandler registration routes
translated button messages once through CallNextProc, retaining coordinates for
graphicsApiReplacer. Native mouse handling, hit testing and queued player
commands still own all game effects. Focus/modal transitions cancel translated
holds through the existing native reset boundary and input-frame hook.

Profile schema 3 accepts older saved documents. Existing custom assignments are
preserved; formerly implicit native group numbers become explicit bindings.
New optional actions start unbound in migrated profiles. Reset a preset to get
its updated defaults, or bind individual new actions in the editor.

## Reuse and runtime binding review

No new native hook, fixed executable address, signature scanner or command
executor is introduced. The existing resolved openBuilding, viewport focus,
control-group and deselect submission functions provide the new effects.
Building serials use owner+2, verified in the original openBuilding code in both
local SHC and Extreme fixtures. UI 1.0.1 manager.lookupModalMenu supplies the
Extreme HUD bounds; graphicsApiReplacer 1.3 retains coordinate conversion.
Grid uses the actual active toolbar item and original callback/parameter,
including status controls sharing the verified toolbar handler, rather than
copying recruitment/market command tables. The input hook only refreshes mouse
ownership while translated buttons are held and checks bookmark lifetime while
bookmarks exist. The existing optional Recorder observer clears local bookmarks.

Native acceptance exposed that queued deselection alone leaves the local unit
highlights active. The original pointer handler calls deselectAllUnitsOneByOne
before queueClickNavigateMenuOrEscape. Modern selection now uses that same pair,
with the local-clear function resolved by UCP AOBScan. Its body and call sequence
were inspected; the signature is unique in both local executable fixtures.
It is an event-time native operation, with no per-frame unit scan added.
Main-menu Options uses UI's registered modal 44; Load retains its verified list
owner and now also works from screen 41. Map descriptions, chat and name fields
remain distinct text owners. Native tests also exposed a stale selectedBuilding
value after closing a status panel: recall now requires screen 16 before treating
that building as already selected.

Native scenarios still to record for this candidate: assignment/recall and
identity reuse; Modern selection/drag/orders/cancel and HUD ownership; keyboard
placement/recruitment/trade; fresh recording/playback and state restore.
