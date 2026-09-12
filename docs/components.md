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

`profiles.lua` separates draft and committed state. Apply persists before
activating; Cancel discards. Existing saved preferences take precedence over
launcher bootstrap defaults. Complete catalog validation covers native/custom
conflicts, atomic key swaps and imported JSON. The profile schema remains
experimental until the required catalog is complete.

`store.lua` alternates two checksummed, validated files, verifies writes by
reading them back and retains the last good file after a failed write. UCP3.0.7
public io.open supplies the fixed installation-local boundary. A named mutex
prevents a second profile writer. The in-game editor imports/exports a separate
exchange pair; it cannot use a profile name as a filesystem path. Framework
userdata PR142 remains separately owned and is not required for this boundary.

`editor.lua` drives the real native view in `native/editor_view.lua`, using the
UI owner's public menu/modal API and explicit arrays. It supports search/groups,
profiles, capture/clear/reset/swap, Apply/Cancel and profile exchange. Text is
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
