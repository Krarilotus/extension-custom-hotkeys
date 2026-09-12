# Local development module

This is an incomplete development artifact. A draft Store 3.0.7 proposal and a
downloadable test ZIP are being prepared; public Store publication remains held.
Do not advertise keyboard-only, multiplayer, replay or Extreme compatibility.
The native acceptance ledger remains authoritative.

Version 0.1.4 is the unrestricted integration tester build: no Recorder API
version requirement and no Hotkeys playback-status lock. Optional Recorder
lifecycle notifications still cancel old gestures across world replacement.
Native screen/control eligibility, text focus and existing game save/load
availability remain the behavior of the implemented actions.

Commit the intended source, then run `python tools/build.py`. The builder reads
that exact Git commit, excludes working changes and creates
`dist/custom-hotkeys-0.1.4.zip` plus its SHA-256/file manifest. It does not bundle
licensed game files, dependency binaries, task diagnostics or saved profiles.
The ZIP has the standard UCP module root (`definition.yml`, `config.yml`,
`init.lua`, `code/`). The same `files.xml` controls both the local builder and
the Store's official module packager. Store descriptions and screenshots are
served online, not copied into every game installation.

Use a separate test installation. Place the ZIP in `ucp/modules`, enable
Custom Hotkeys in its test configuration and resolve the pinned dependencies.
This version requires UCP3.0.7 or later, UI1.0.1, LuaJIT1.0.0, cffi1.0.0,
winProcHandler1.0.0 and graphicsApiReplacer1.3.0. The exact reference SHC1.41
image hash is checked at runtime; Extreme and other images are rejected.

The module's required configuration sets UCP2-Legacy's hotkey option
`o_keys.enabled=false` when Legacy is present. Other Legacy settings are not
rewritten. An active or unverifiable Legacy hotkey configuration fails at module
load, before extension enable callbacks. Recorder is optional; when present it
must expose input-state API version1 and finish initialization successfully.
The prerequisite Recorder 0.50.4 implementation and bounded single-player checks
are described in [Recorder integration](recorder-integration.md). Recorder 0.50.3
and the published Hotkeys 0.1.1 ZIP do not support this combination.
Correct an incompatible configuration and start a new process;
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
