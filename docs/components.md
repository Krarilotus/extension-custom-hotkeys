# Component and native integration contracts

`binding.lua` represents Set-1 scan identity/E0 or mouse buttons1-5, with Ctrl/Shift/Alt.
It rejects modifier-only, E1/Pause, Windows and reserved system combinations.
AltGr/composition retain native ownership. Ctrl+Shift+F12 is a recovery chord
inside eligible parents; it never overrides a native text field or another modal.

`context.lua` validates positive facts for screen, panel, modal, focus, selection,
targeting, authority, session and lifecycle. `native/scene.lua` and `gameplay.lua`
resolve the audited SHC/Extreme fields through UCP bindings. SP and MP use the
same native action owners; native save/load restrictions are retained.
Both native unit interaction fields contribute to pending-gesture identity.
Two-PC acceptance is manual. Recorder availability/version/status does not lock input.

`router.lua` consumes each remapped press once, suppresses its character/debt
messages, and cancels holds/capture/pending input at barriers. It rechecks context
at dispatch and never retries uncertain native calls. `messages.lua` and
`native/chain.lua` use the existing winProcHandler chain. The x86 callback and
private LuaJIT state remain pinned because the owner has no unregister API.
Focus cancellation precedes the graphics wrapper, which may consume focus events.

`preflight.lua` rejects conflicting Legacy o_keys settings before enable-time
patches. The shipped framework's load
and normalization path was exercised in both Legacy load orders. Legacy source
is unchanged. `address_bindings.lua` uses UCP AOBScan/AOBExtract at initialization,
with named bindings copied once into the private LuaJIT state. UI exports supply
mouse primitives and registered menus. Fixed-address and private hash-allowlist
adapters were deleted. The single UCP input insertion validates displaced bytes;
it adds no command, Recorder, load or restore hook. See [binding review](native-bindings.md).

`navigation.lua` invokes the active enabled MenuItem's original handler once at
the input frame after revalidation. Direct construction/Grid actions retain the
world cursor. Traversal focus and `targeting.lua` use the visible cursor, native
hit testing and normal mouse input. Each aim/press/release/drain phase rechecks
context and the selected control/projection. Building
placement and unit orders retain original validation/command handling. Camera
pan owns local input flags and cancels on barriers. Stance uses the native
submission wrapper, not the internal stance mutator.

`dialog_context.lua` resolves non-text Options/confirmation dialogs and optional
Automarket through UI's modal registry. Focused slider adjustments read the
original handler's bounds/current value and submit its bounded step through that
same handler. Text owners never become gameplay contexts. `mouse_messages.lua`
and the existing Windows chain translate configured buttons once, preserving
coordinates and the downstream graphics/input owner. Native selection, targeting
and command submission retain gameplay effects.

Building groups validate native identity serials and ownership. Camera bookmarks
are local viewport positions. Only sessions with bookmarks perform their small
lifetime check; there is no per-frame building/unit census or simulation hook.

`bindings.lua` holds the sparse dictionary of explicit choices from the active
UCP config and derives the effective bindings from it, the layout, plugin
suggestions and provider defaults. It separates draft and committed state.
Apply writes only the changed explicit entries before activating; Cancel
discards. Complete catalog validation covers native/custom conflicts and
atomic key swaps.

`config_file.lua` writes those entries into the `custom-hotkeys` block of the
active config file and checks the result with the framework's YAML reader
before replacing the file. A named mutex prevents a second writer.
`legacy_profiles.lua` reads the 0.2 profile slots once for migration.

`editor.lua` drives the real native view in `native/editor_view.lua`, using the
UI owner's public menu/modal API and explicit arrays. It supports search/groups,
layouts, capture/clear/reset/swap and Apply/Cancel. Text is
UTF-8 in storage and explicitly converted to the verified native font code page.
Native text widths bound labels and keep the editing caret/selection visible.
Game-language labels and Windows key names are cached. Source language coverage
and component encoding checks do not imply native/font/translation acceptance.

Tests run production components in Lua5.4 and LuaJIT, including real temporary
files and injected failures. Older native task-only F-key diagnostics bypassed
physical lookup and are excluded from product code. The user-requested separate
SendInput scan-code test harness now exercises the actual production binding
path; it does not establish physical-hardware acceptance. See the native
evidence documents for observed outcomes, mouse preparation and failed checks.

Current implementation and exact passed/remaining checks are in
[0.1.6 evidence](features-0.1.6.md). A completed native Recorder capture/playback
matched resource and RNG checkpoints; this does not establish the full state-
restore, text/focus, layout/language, performance or two-PC acceptance matrix.
Draft PR2 and issue1 remain open pending the remaining work and normal review.
