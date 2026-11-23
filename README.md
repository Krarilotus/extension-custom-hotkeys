# Custom Hotkeys for Stronghold Crusader

Bindings live in the active UCP config, one dictionary per config: Apply in
the in-game editor writes the explicit choices there, and every launch derives
the rest from the layout, plugin suggestions and other modules' defaults. See
[bindings in the UCP config](docs/bindings-config.md), including the one-time
migration of 0.2 profiles.

Version 0.2.18 enables camera and view bindings in the scenario editor, keeps
gameplay bindings available after a closed ally dialog or during an AI lord
video, and supports quicksave/quickload with compatible Save and Load menu
extensions such as Autosave. Startup failures are logged.

Version 0.2.1 shortens native build-category and placement-return menu switches for hotkeys, so the next panel accepts its keys on the next game frame.
The editor remains in the game's main and in-game Options menus.
It also allows the same binding in different native construction/unit
panels. Woodcutter, Wheat Farm and Catapult can share a key; Woodcutter and
Quarry still conflict because both are available in Industry. Global actions
still conflict with panel actions wherever they overlap. Inactive buttons never
receive the key, and held keys must be released before a new panel can use them.

Uses the existing UCP 3.0.7 `core.AOBScan`, shared cache and `utils.AOBExtract`.
No replacement framework files or new scanner API are required.

Development of one UCP3 extension for in-game rebinding, saved in the UCP config,
and keyboard access to native menus, building placement and unit targeting.

This is an incomplete test version, not an accepted release.
The [0.1.9 feature candidate](docs/features-0.1.9.md) includes keyboard/mouse rebinding,
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

The current branch contains the binding router, bindings saved in the UCP config,
the native binding editor and Windows input transport. Direct menu, building and Grid shortcuts invoke the active native button
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
customization options are needed. Open **Options > Custom Hotkeys** from the main
menu or from the in-game pause menu, or
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

## Register actions from another module

In your module's `enable`, detect the optional action API. Register your
actions there, before Custom Hotkeys starts its `afterInit` callback. Use your
module name in the stable ID. The player can find the action by its label or
category, rebind it, clear it or reset it under **Options > Custom Hotkeys**.

```lua
local hotkeys=modules['custom-hotkeys']
if hotkeys and type(hotkeys.registerAction)=='function' then
  hotkeys:registerAction{
    id='ext.my-overlay.toggle',
    label=translatedActionName,
    category=translatedCategoryName,
    context={kind='world'},
    default=false,
    callback=toggleOverlay,
  }
else
  -- Keep the original input path available when the shared API is absent.
  installOriginalInput()
end
```

Use a lowercase ID such as `ext.my-overlay.toggle`. Label and category tables
use `en, de, fr, ru, hu, tr, ch, es, fa` with UTF-8 values. `registerAction` returns true and raises on
invalid, duplicate or late registration. Registration lasts for the process.

- `context={kind='world'}` selects the live game map. Use
  `{kind='panel',tab=number}` for a narrower native toolbar tab or
  `{kind='editor'}` for the map editor canvas. `{kind='modal',id=number}`
  matches a verified native Options or Load modal. The modal owner checks its
  own controls. Native text entry and editor tools keep their own input.
- `default` can be omitted or false. Suggest a physical keyboard chord
  `{scan=number,extended=false,mods=0}`, mouse button
  `{button='x1',mods=0}` or vertical wheel direction `{wheel='up',mods=1}`.
  Modifier flags are Ctrl=1, Shift=2 and Alt=4. Windows shortcuts and the
  recovery chord remain reserved.
- `callback(context,event)` runs the action. Return true for a successful
  action. The callback owns any feedback, such as a sound. Optional
  `release()` pairs with a keyboard or mouse-button hold and runs after
  key-up, focus loss, a context transition or a binding change.
  Bare modifiers and wheel holds are outside this API.
- One context receives the gesture. Specific panels take priority over
  general map actions. Recognized modals and the editor have their own
  checked input ownership. Same-scope conflicts and retained native
  bindings use the existing editor checks. A module's default yields to any
  layout or explicit binding on the same chord.

Family presets and plugins can suggest a key in their ordinary `config.yml`.
A suggestion wins over the layout and module defaults; explicit player choices
in the UCP config win over suggestions. The example suggests leaving Zoom In
unbound.

```yaml
config-sparse:
  modules:
    custom-hotkeys:
      config:
        bindings:
          resolution-based-zoom:
            in:
              contents:
                suggested-value: false
  plugins: {}
```

A missing provider's entries stay in the UCP config for its return. When a
provider's new version changes an action so that a saved chord no longer fits,
for example because the action became a hold, which cannot use the wheel, the
chord stays in the config but the action starts unbound for that launch.
Edits in the editor are still checked strictly. Restart the game after
changing the active modules or launcher config.
