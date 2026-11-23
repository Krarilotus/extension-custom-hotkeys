# Bindings in the UCP config

Open Options > Custom Hotkeys from the main menu or in-game pause menu, F12, or the reserved Ctrl+Shift+F12
recovery chord while an eligible menu/game screen is active. Recovery does not
override native text fields, another modal or an unsupported session.

Select an action and press Enter (or double-click its row) to capture a key or
mouse button. Delete unbinds it. A conflict preserves both bindings and offers
Swap keys; the swap is atomic and still rejects collisions with a third action
or a native action left without a required replacement. The Profile page picks
the layout (Game Default, Modern RTS or Grid); explicit choices stay. Reset
action and Reset profile return actions to inheritance. All of these affect only
the draft. Apply saves and activates the draft. Cancel discards it.

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

Where two chords collide, the action from the lower layer stays unbound; on
a tie, the later one in catalog order does (built-in actions in the order
they are declared, then other modules' actions by ID). An action never takes a game key
whose own action still needs it. An unbound action gets its chord back when
the action that displaced it yields as well. An explicit entry that yields, or that no
longer fits a provider's changed action, is set aside: it stays in the config,
the action is unbound and a warning is logged. It returns as soon as its chord
is free, and assigning that chord to another action replaces it. The editor
derives its bindings the same way after every change, so Apply routes exactly
what the next launch reads.

A value the launcher requires (`required-value`) appears in config-full with a
different value than the player's entry. It wins over every other layer, and
the editor refuses to change or reset that action, or the layout when the
layout is required. A required value equal to the player's entry, or one
without any player entry, cannot be told apart from an ordinary value in the
file and stays editable.

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
other modules' values. Apply therefore rewrites only the `custom-hotkeys` block
of `config-sparse` and `config-full` in the file the game was started with,
from its parsed content: comments and null values inside that block are not
kept. All other lines, including their line endings, stay byte-identical. The
result must parse back with the framework's YAML reader to exactly the intended
document. It is written next to the config and replaces it in one atomic rename.

The file is left unchanged, and the editor reports that the config could not
be saved, when:
- it changed since this game loaded it or last wrote it, for example because
  the launcher saved it meanwhile (restart the game to load the new file);
- it is marked inactive, or its config-full no longer lists this Custom
  Hotkeys version as active;
- it is not in the launcher's block style, for example in flow style.

Reset removes the explicit entry. When that entry had replaced a plugin
suggestion, the file no longer contains the suggestion, so the layout or
provider default applies until the launcher saves this config again.

One game process at a time writes hotkeys; Apply reports an error in a second
process. The launcher keeps its own copy of the config while it is open, and
UCP 3.0.7's launcher does not reload it when the game exits. Reopen the config
in the launcher before saving there, or in-game changes made since it was
loaded are overwritten.

## Migration from 0.2

Custom Hotkeys 0.2 kept named profiles in `ucp/custom-hotkeys-profiles-a.json`
and `-b.json`. A UCP config that has no Custom Hotkeys entries yet takes over the
active one of those profiles on its first start with 0.3:

- its layout is written as `layout`;
- each built-in chord or clear that differs from that layout becomes explicit;
- every entry for another module's action becomes explicit, including chords
  0.2 had set aside, because a saved profile cannot show whether it came from a
  suggestion. Reset returns any of them to inheritance.

`layout` stays when actions are reset, so each config is imported into once.
A config that already has entries is never changed by the import. If the
config cannot be written at that start, the editor still holds the imported
choices and the next successful Apply writes them; otherwise the next start
imports again.

The 0.2 files are only read, never changed, so 0.2 keeps working with them.
While they exist, a new config without Custom Hotkeys entries starts from that
profile too; delete or move them to start new configs from the layouts. Only
the active profile is imported: make another one active in 0.2 to import it.
The profile exchange files of 0.2 are not read.
