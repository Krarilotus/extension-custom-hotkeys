# Native editor integration evidence

11 September 2026, GamerGrill, isolated SHC 1.41 / UCP 3.0.7 test install.
Executable SHA-256: `3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
UI 1.0.1, cffi 1.0.0, LuaJIT 1.0.0, winProcHandler 1.0.0 and
graphicsApiReplacer 1.3.0; Legacy and Recorder inactive.

This verifies part of the editor integration, not the complete extension.
The diagnostic catalog contains only the settings action. It is not a release
catalog or a keyboard-only acceptance result.

## Observed native results

PID 1964: opened Custom Hotkeys from its new native main-menu button. Created
profile `p` using the editor's text field, typed `p`, and accepted with Return.
Cleared the settings action, observed Unbound, and applied. Reopened, reset that
action to F12 in the draft, then cancelled. The saved profile remained unbound.

The current public UCP `io.open` boundary wrote
`ucp/custom-hotkeys-profiles-a.json`, generation 1, 298 bytes. Payload checksum:
`b856690682abc005e0cfde381e576c0511d562f578d9e197feed97e012c73920`.
Default retained F12; `p` retained its explicit unbound value. No launcher
profile or game save was changed.

Exited normally with Alt+F4. PID 7432: restarted the same install, opened the
editor, and visually verified selected profile `p` and Unbound. Startup receipt
also reported profile `p`, modal 2041 and listener priority -110000.
Exited normally and checked process absence. Desktop released at 16:05:47 CEST;
the isolated baseline configuration was restored.

Task-local receipts: `Roadmap/Investigations/Custom-Hotkeys/native-evidence/`
contains `ui-probe-1964-build.json`, `profile-1964-a.json`, and the two process
logs. The build receipt lists SHA-256 for each staged source file. The exact
normalized configuration excludes Legacy and Recorder.

## Fixes learned from native runs

The LuaJIT API is `executeString(source, path, convert, cleanup)`. Passing the
conversion flag second initialized the runtime but failed receipt validation.
State and library lifetime are now pinned before native initialization.

The original tutorial book overlaps the lower right menu area. The knight's
Bink animation repaints the area above it. The new button occupies the gap at
menu-local (155,462), 335 by 24 pixels, below Custom Scenarios and above the
original y=490 hit rectangle. It stays visible with the animation running.
Native screenshot inspection confirmed the editor border, labels and controls.

## Remaining acceptance

Entry used the mouse. Mouse controls and the logical text-field Return worked;
the automation backend still supplies scan=0 and cannot verify physical capture,
F12 entry, recovery chords, held keys or layout behavior. See
[testing environment](testing-environment.md). Conflict/reassignment with real
physical keys, full action catalog, gameplay settings access, native menu
navigation/targeting, text-field regressions, encoding/localization, minimum
resolution, MP and Recorder integration remain open. No gameplay, command-count,
replay or merge claim follows from these editor checks.
