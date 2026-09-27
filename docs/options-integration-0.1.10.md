# Options integration and native check, 27 September 2026

The Custom Hotkeys entry is inside the native Game Options panel on the main
menu (modal 44) and in-game (modal 12). Both rows use the existing 300×27 game
button with the native font, centered label and adjacent-row spacing. Opening
the editor replaces the Options modal; Apply or Cancel restores that exact
Options root. Repeated open/close cycles worked on both routes. F12 remains an
additional entry on eligible screens.

| Capability | Existing owner reused | Decision |
| --- | --- | --- |
| Options menu identity and pointer | UI 1.0.1 `remote.interface.modalMenuAddress` and `api.ui.Menu:fromPointer` | Reuse registered modal 12/44 only; no private address or new scan. |
| Native menu activation and geometry | UI 1.0.1 `game.UI.Menu`, `activateModalMenu`, `ButtonState` | Extend the verified Options item arrays, keep native callbacks/width, and use the existing button and font renderer. UI 1.0.1 already supplies the needed API; no upgrade. |
| Input, modal and focus ownership | Existing `scene`, `dialog_context`, `editor_view`, winProcHandler chain | Reuse current screen/modal/text/focus checks. Restored Options with textModal 0 is recognized only at the registered active modal identity. |
| Recorder controls | Recorder 0.50.4 `code/native-ui.lua:extendPause` and `code/ui.lua` Skirmish Replays button | Hotkeys changes only modal 12/44. Recorder's pause modal 5 and Skirmish menu array/coordinates are untouched. |
| Runtime binding | Existing UCP `core.AOBScan` / UI `utils.AOBExtract` and Hotkeys address bindings | No new executable address, hook, scanner or package dependency. |

The native fixture was SHC 1.41 (SHA256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`),
UCP 3.0.7-77c6a, UI 1.0.1, Recorder 0.50.4 and Automarket 1.1.0.
The signed-off visual states are [main Options](images/hotkeys-010-options-menu.jpg)
and [in-game editor](images/hotkeys-010-editor-ingame.jpg). The stored Grid
schema-2 profile migrated its formerly unbound camera slots to the preset's
Shift+Alt+number / Ctrl+Alt+number bindings without changing its older values.
The test game was closed and the desktop released; the isolated fixture's
configuration, AOB cache and profile files were restored to their baseline hashes.

Recorder's Replays entry is on Skirmish setup rather than the Options roots.
The observed tutorial and Castle Builder pause panels did not display Recorder's
conditional replay control. This check establishes coexistence and menu ownership,
not a visual pass of the conditional Recorder control, gameplay commands,
multiplayer or replay/state-restore acceptance. Those remain separate checks.
