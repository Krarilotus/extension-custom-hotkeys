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
Grid uses the actual active panel block and original callback/parameter,
including recruitment/status controls with their different native handlers,
rather than copying recruitment/market command tables. The input hook only refreshes mouse
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

Automarket 1.1.0 (`extension-automarket` source 858890f) uses UI modal 2025 and
native MenuItems for goods, sliders, Save and Close. Its trigger and all handlers
were inspected. Dialog navigation reuses UI manager.lookupModalMenu and the
existing reader/activation path; it does not copy Automarket settings or its
protocol. The registered pointer must match the actual active composition, with
no text editor or covering modal. Optional lookup adds no Automarket dependency.
The original Options context helper became the shared dialog context helper.

The same registry now supplies native Options, Video, Sound, Gameplay and Yes/No
dialogs (5/6/7/11/12/13/44). This removes the redundant Options-menu AOB scan.
Original Menu constructor arrays, UI1.0.1's MenuItem ABI and native speed/volume
slider handlers were inspected. Left/Right on a focused dialog slider calls its
event1 bounds/value query, event7 owner step and a clamped native event2 change.
It uses the MenuItem slider state, including the value used by native rendering.
Automarket uses the identical published slider ABI and retains its Save protocol.
No setting value is written directly and no slider hook/polling is added.
Gameplay/Sound sliders and keyboard return passed in PID30484 below. Extreme's
Yes/No cancellation passed in PID20684; Video still needs a dedicated native check.

## Native checks, 12 September

SHC 1.41, UCP 3.0.7-77c6a, UI 1.0.1, Recorder 0.50.4, Automarket 1.1.0,
English game with German Windows key labels; Legacy absent.

- PID34564, f4c3535: Enter capture accepted middle mouse; Apply/reopen preserved
  it. This fixed the earlier editor view-copy error; the failed run is retained.
- PID34828, f4c3535: Shift+Tab twice, Enter, Shift+Tab twice, Enter, Tab, Enter
  loaded the prepared skirmish from the main menu without mouse input. Grid H,
  numpad targeting and Enter placed a mercenary post for 10 wood. Ctrl+N opened
  its panel. Tab navigation plus Enter recruited one Arabian archer for 75 gold.
  Ctrl+S saved the dedicated quickslot; the next process loaded that save.
- PID35324, 955b132: Ctrl+N then Grid A recruited one archer (1925 to 1850 gold).
  Industry/Grid selected a market; numpad target/confirm placed it (90 to 85
  wood). Ctrl+M and Grid opened food/raw-material categories and selected bread
  and wood. Native Buy rejected bread because this fixture had no granary;
  no successful trade is claimed. Grid also reached the injected Automarket
  button. The overlay then exposed an input/navigation conflict requiring the
  shared dialog ownership change above.
- PID25340, 46556be: the keyboard route loaded the quickslot, placed one market,
  opened Automarket with Grid A, and traversed its controls with Tab/Shift+Tab.
  Enter on Close dismissed it without changing the background status panel.
  Native market Buy bought5 wood for20 gold (85->90,1925->1905). Automarket's On
  and Save/Close callbacks worked from keyboard navigation. Mission exit finalized
  recording20260912-151956-0001 with4 commands: native menu escape, one building,
  one Buy and one Automarket protocol submission. Its playback finished at20732
  (10619 elapsed ticks), consuming all4 commands with matching resource, RNG and
  full RNG checkpoints. F12/Cancel worked during playback. Error log was header-only;
  normal close/PID absence verified, desktop released17:31:32, baselines restored.

- PID30484, 97cfe4b: keyboard navigation reached main Options, Gameplay Options
  and Sound Options. The speed slider displayed60->59->60 and music0->1->0
  through the original slider handler/state. Keyboard Back returned from both
  subdialogs; Load opened the task quickslot and F12 opened the239-action editor.
  Normal process exit and desktop handoff verified18:09:05. This session was not
  finalized as a Recorder recording and is not additional playback evidence.

- Extreme PID20684, 97cfe4b: startup with Recorder/Automarket, keyboard main
  Options and the empty Load list, and Yes/No cancellation returned correctly.
  Options Back and the skirmish opponent picker used mouse fallback. Gameplay
  was not reached. The process closed normally and the desktop was released at
  18:35:31; config/profile baselines were restored. Cleanup was delayed by missed
  desktop handoffs; the next worker's Extreme launch was blocked until close.

These processes exited normally and desktop reservations were released. Earlier
Alt+F4-only captures were not finalized and remain unaccepted; the later normal
mission-exit capture above is the completed playback evidence. Earlier native
checks established building-group recall, camera bookmarks and Modern right-click
movement/left-click deselection; drag, queued orders, building identity reuse,
full text/held/focus coverage, Extreme reruns, alternate-profile playback and
state restore still need acceptance. Two-PC multiplayer is deferred to manual
testers and does not block implementation or tester access.
