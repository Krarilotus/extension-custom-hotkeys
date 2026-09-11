# Custom Hotkeys for Stronghold Crusader

Development of one UCP3 extension for in-game rebinding, persistent local profiles
and keyboard access to native menus, building placement and unit targeting.

This repository is under development. It is not a playable or accepted release.
Native actions must retain the game's validation, authority and synchronized
command path. Legacy hotkey modifications must be disabled before activation.

Historical requests:
[configurable hotkeys](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch2/issues/432)
and [WASD replacements](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch/issues/8).

Completion requires native keyboard-only, two physical multiplayer peers and
recorder replay/state-restore acceptance, localization, an installable tested
artifact and verified reviewed merge. Work in progress remains draft.

The current branch contains the binding router, profile transactions, a storage
component, editor controller and Windows input transport. Native action adapters, the actual in-game view and
the complete action catalog are still being implemented. There is no installable
Custom Hotkeys artifact yet. Test actions are fixtures, not supported gameplay.

Run `python -m pip install -r tests/requirements.txt` and
`python -m pytest tests -q`. The same component cases run in Lua 5.4 and LuaJIT;
they do not establish native ABI, keyboard-only or multiplayer compatibility.

See [component contracts](docs/components.md) and the
[pending manual two-PC route](docs/manual-multiplayer.md).
