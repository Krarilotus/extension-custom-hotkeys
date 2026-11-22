# Bindings in the UCP config

Open Options > Custom Hotkeys from the main menu or in-game pause menu, F12, or the reserved Ctrl+Shift+F12
recovery chord while an eligible menu/game screen is active. Recovery does not
override native text fields, another modal or an unsupported session.

Select an action and press Enter (or double-click its row) to capture a key or
mouse button. Delete unbinds it. A conflict preserves both bindings and offers
Swap keys; the swap is atomic and still rejects collisions with a third action
or a native action left without a required replacement. The Profile page picks
the layout (Game Default, Modern RTS or Grid) and resets every action to it.
Reset action, Reset profile and the layout choice affect only the draft. Apply
saves and activates the draft. Cancel discards it.

## One dictionary per UCP config

Each UCP config file holds its own Custom Hotkeys dictionary under
`custom-hotkeys.config`:

- `layout`: `game-default` (used when absent), `modern-rts` or `grid`.
- `bindings.<module>.<action>`: an explicit chord, or `false` for an explicit
  clear. Actions of other modules use their registered ID `ext.<module>.<action>`
  without the `ext.` prefix. Built-in actions sit under `bindings.custom-hotkeys`,
  split at each dot of their ID.

Only explicit choices are stored. Every launch derives the effective bindings
for the enabled modules in this order:

1. the explicit entry in the config;
2. a plugin suggestion for the same path;
3. the layout's chord, or the providing module's default.

An inherited chord that would collide with an explicit one stays unbound. A
suggestion or provider default is used only where its chord is free, in stable
ID order. An explicit entry whose chord is taken by another explicit entry, or
that no longer fits a provider's changed action, is set aside for that launch:
it stays in the config, the action starts unbound and a warning is logged.

Entries for modules that are not enabled are kept unchanged. When the module
returns, its chord or explicit clear returns with it. Several UCP configs, and
their exports and imports in the launcher, therefore carry their own hotkeys.

```yaml
config-sparse:            # launcher user values: the explicit dictionary
  modules:
    custom-hotkeys:
      config:
        layout:
          contents:
            suggested-value: grid
        bindings:
          custom-hotkeys:
            game:
              quicksave:
                contents:
                  suggested-value: {scan: 65, mods: 1, extended: false}
          resolution-based-zoom:
            in:
              contents:
                suggested-value: false
            out:
              contents:
                suggested-value: {button: x2, mods: 0}
config-full:              # what the framework loads: explicit values plus plugin suggestions
  modules:
    custom-hotkeys:
      config:
        layout:
          contents:
            value: grid
        bindings:
          custom-hotkeys:
            game:
              quicksave:
                contents:
                  value: {scan: 65, mods: 1, extended: false}
          resolution-based-zoom:
            in:
              contents:
                value: false
            out:
              contents:
                value: {button: x2, mods: 0}
```

A plugin suggests a chord through the same path in its own `config.yml`, with
`contents.suggested-value`. Modifier flags are Ctrl=1, Shift=2 and Alt=4.

## Apply writes the active config

UCP 3.0.7 has no config writer for modules, and its YAML round trip changes
other modules' values. Apply therefore replaces only the `custom-hotkeys` block
of `config-sparse` and `config-full` in the file the game was started with.
All other lines stay byte-identical. The result must parse back with the
framework's YAML reader to exactly the intended document before it replaces
the file through a temporary copy. A file the writer cannot place this block
in safely, for example one in flow style, is left unchanged and the editor
reports that the config could not be saved.

Reset removes the explicit entry. When that entry had replaced a plugin
suggestion, the file no longer contains the suggestion, so the layout or
provider default applies until the launcher saves this config again.

One game process at a time writes hotkeys; Apply reports an error in a second
process. The launcher keeps its own copy of the config while it is open.
Save in the launcher only after reloading the config, or in-game changes made
since it was loaded are overwritten.

## Migration from 0.2

Custom Hotkeys 0.2 kept named profiles in `ucp/custom-hotkeys-profiles-a.json`
and `-b.json`. On the first start of 0.3, the active profile moves into the
active UCP config, and both files are renamed to `*.json.migrated`:

- its layout becomes `layout` when it differs from the inherited one;
- each built-in chord or clear that differs from that layout becomes explicit;
- every entry for another module's action becomes explicit, because a saved
  profile cannot show whether it came from a suggestion. Reset returns any of
  them to inheritance.

Entries already in the config win. Only the active profile moves. To move
another one, rename the `.migrated` files back, make that profile active in 0.2,
and start 0.3 with the UCP config that should receive it. If the
config cannot be written, the files stay in place and the migration runs again
on the next start. To return to 0.2, rename the `.migrated` files back.
The profile exchange files of 0.2 are no longer read.
