# Local development module

Version **0.1.5** is the native-binding and cursor-preserving construction
preview. The Store3.0.7 proposal remains a draft; complete keyboard-only,
multiplayer and replay acceptance is outstanding. See the
[binding review and native evidence](native-bindings.md).

Commit the intended source, then run `python tools/build.py`. It builds that
exact commit into `dist/custom-hotkeys-0.1.5.zip` and a SHA256 manifest. The
same `files.xml` controls local and official Store packaging. Game binaries,
dependencies, profiles, diagnostics, test fixtures and screenshots are excluded.

Place the ZIP in `ucp/modules` in a separate test installation, select the new
version and activate Custom Hotkeys. There is no second activation switch.
Press **F12** in-game; **Ctrl+Shift+F12** is the reserved recovery route. Labels
follow the game language. Game Default, Modern RTS and Grid profiles are included.

Requires UCP3.0.7+, UI1.0.1, LuaJIT1.0.0, cffi1.0.0, winProcHandler1.0.0 and
graphicsApiReplacer1.3.0. SHC1.41 and Extreme1.41 use UCP-resolved native
bindings, without a private executable hash/filename allowlist. Other executable
variants still require fixture and native testing as recorded in the review.

Legacy is optional. Its conflicting `o_keys.enabled` setting is required false
when present, with runtime validation before extension enable callbacks. Legacy
source and unrelated options are unchanged. Restart after changing active module
combinations; installed input hooks cannot be removed safely from a running game.

Recorder is optional, with no Hotkeys Recorder-version or playback-status lock.
Optional lifecycle notifications cancel old held gestures across world changes.
Recorder0.50.4 and Automarket1.1.0 were loaded during the bounded native checks;
this does not establish complete replay or multiplayer correctness.

Profiles and portable exchange files follow [the profile contract](profiles.md).
The next launcher run does not replace in-game bindings. Development profiles
may need explicit migration as missing actions are implemented. Preserve the
test installation's existing profiles instead of replacing them to pass a test.

To disable Hotkeys, exit normally, remove it from the next active configuration
and restart. Vanilla shortcuts then operate normally. Re-enabling Legacy hotkeys
is a separate configuration choice requiring a clean launch.
