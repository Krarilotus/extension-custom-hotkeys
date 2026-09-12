# Custom Hotkeys for Stronghold Crusader

Development of one UCP3 extension for in-game rebinding, persistent local profiles
and keyboard access to native menus, building placement and unit targeting.

This is an incomplete test version, not an accepted release.
The [0.1.6 candidate](docs/features-0.1.6.md) includes keyboard/mouse rebinding,
building groups, camera bookmarks, keyboard targeting and native panel controls.
UCP byte-pattern resolution and original button callbacks preserve the construction cursor.
Crusader and Extreme are open for testing, including multiplayer and Recorder.
Native actions must retain the game's validation, authority and synchronized
command path. Legacy hotkey modifications must be disabled before activation.

Historical requests:
[configurable hotkeys](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch2/issues/432)
and [WASD replacements](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch/issues/8).

Two-PC multiplayer is deferred to manual testers and does not block development
or tester access. Full native acceptance and normal reviewed merge remain open.

The current branch contains the binding router, persistent profiles, native
profile editor and Windows input transport. Direct menu, building and Grid shortcuts invoke the active native button
without moving the cursor. Positional navigation and world targeting retain
the native mouse-input path.
The three presets are Game Default, Modern RTS and Grid. Modern RTS separates
left-click selection from right-click orders; Grid follows physical key positions
and the currently visible native panel. Ctrl+number assigns units or the selected
owned building, number recalls it, and a second press focuses it. Camera positions
use Shift+Alt+number to assign and Ctrl+Alt+number to recall. Numpad 8/4/2/6 moves
the target, 5 centers it, Enter confirms and Decimal cancels. All are configurable.
See [presets](docs/presets.md) for defaults and migration behavior.

Activate the module in UCP and start the game: no additional launcher switch or
customization options are needed. Open **Custom Hotkeys** from the main menu or
press **F12** in a supported menu/live single-player or multiplayer game. **Ctrl+Shift+F12** is
the recovery shortcut if F12 was reassigned. Change bindings and select **Apply**
to save them. The editor uses the **game language**, read through UCP after game
initialization. Store descriptions use the launcher's language.

Legacy is not a dependency. When present, its `o_keys.enabled` option is required
to be false by `config.yml`, with a second runtime check before patches activate.

The [development package](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/install-development.md) is built reproducibly
from a committed tree with `python tools/build.py`. Native acceptance of the
complete packaged workflow is pending; bounded native editor checks are recorded.

Run `python -m pip install -r tests/requirements.txt` and
`python -m pytest tests -q`. The same component cases run in Lua 5.4 and LuaJIT;
they do not establish native ABI, keyboard-only or multiplayer compatibility.

See [component contracts](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/components.md) and the
[pending manual two-PC route](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/manual-multiplayer.md).
The [three development presets](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/presets.md) share the binding catalog and
include a native-panel grid. The [compact editor](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/editor-layout.md) shows18 rows and reuses
the game's native scrollbar.
Native development evidence covers [profile editing](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/native-editor-evidence.md)
and [menu navigation](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/native-navigation-evidence.md); neither is a complete
keyboard-only acceptance pass.
Additional evidence covers [world actions](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/native-world-actions-evidence.md),
[building placement](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/native-building-evidence.md) and the
[language/encoding contract](https://github.com/Krarilotus/extension-custom-hotkeys/blob/feat/binding-core/docs/localization.md), with their remaining gates.
