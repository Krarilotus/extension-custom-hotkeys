# Local development module

This is an incomplete development artifact. Do not publish it to the extension
store or advertise keyboard-only, multiplayer, replay or Extreme compatibility.
The native acceptance ledger remains authoritative.

Commit the intended source, then run `python tools/build.py`. The builder reads
that exact Git commit, excludes working changes and creates
`dist/custom-hotkeys-0.1.0.zip` plus its SHA-256/file manifest. It does not bundle
licensed game files, dependency binaries, task diagnostics or saved profiles.
The ZIP has the standard UCP module root (`definition.yml`, `init.lua`, `code/`).

Use a separate test installation. Place the ZIP in `ucp/modules`, enable
Custom Hotkeys in its test configuration and resolve the pinned dependencies.
This version requires UCP3.0.7 or later, UI1.0.1, LuaJIT1.0.0, cffi1.0.0,
winProcHandler1.0.0 and graphicsApiReplacer1.3.0. The exact reference SHC1.41
image hash is checked at runtime; Extreme and other images are rejected.

Before launching, disable UCP2-Legacy's hotkey option `o_keys.enabled`. Other
Legacy settings are not rewritten. An active or unverifiable Legacy hotkey
configuration fails at module load, before extension enable callbacks. The
current Recorder combination is also rejected until its lifecycle API is
available and integrated. Correct the configuration and start a new process;
neither implementation can safely be removed from a running game's input chain.

The in-game entry is on the main menu, with F12 as the development binding.
Ctrl+Shift+F12 is the reserved recovery route. Profiles and portable exchange
files follow [the profile contract](profiles.md); the next launcher run does not
replace in-game bindings. The full catalog/default schema is not frozen, so
development profiles may require explicit migration as actions are completed.
Never overwrite another installation's profiles to make a development run pass.

To disable the module, exit the game normally, remove it from the next active
configuration and restart. Vanilla shortcuts then operate normally. Re-enabling
Legacy hotkeys is a separate explicit configuration choice and clean launch.

Packaging verification establishes archive contents and reproducibility only.
Native load, editor operation, restart/persistence, incompatible configuration,
complete keyboard workflows, command counts, performance, languages/layouts,
multiplayer and replay/state restoration still require the documented tests.
