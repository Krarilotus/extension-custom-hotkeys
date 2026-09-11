# Component and native integration contracts

`binding.lua` represents Set-1 scan identity, the E0 flag and Ctrl/Shift/Alt.
It rejects modifier-only, E1/Pause, Windows and reserved system combinations.
AltGr/composition retain native ownership. Ctrl+Shift+F12 is a recovery chord
inside eligible parents; it never overrides a native text field or another modal.

`context.lua` validates positive facts for screen, panel, modal, focus, selection,
targeting, authority, session and lifecycle. `native/scene.lua` and `gameplay.lua`
resolve the audited SHC1.41 fields. Current gameplay integration is live SP only.
Both native unit interaction fields contribute to pending-gesture identity.
Multiplayer and Recorder integration remain explicit gates.

`router.lua` consumes each remapped press once, suppresses its character/debt
messages, and cancels holds/capture/pending input at barriers. It rechecks context
at dispatch and never retries uncertain native calls. `messages.lua` and
`native/chain.lua` use the existing winProcHandler chain. The x86 callback and
private LuaJIT state remain pinned because the owner has no unregister API.
Focus cancellation precedes the graphics wrapper, which may consume focus events.

`preflight.lua` rejects conflicting Legacy o_keys settings and unavailable
Recorder integration before enable-time patches. The shipped framework's load
and normalization path was exercised in both Legacy load orders. Legacy source
is unchanged. `native/identity.lua` and `executable.lua` verify process, working
directory, image/base and executable hash before native addresses are used.
The task owns the checked0x468100 input prefix; it does not add competing command,
recorder, load or restore hooks. Unsupported executable hashes are rejected.

`cursor.lua`, `navigation.lua` and `targeting.lua` use the visible cursor, native
hit testing and normal mouse input. Each aim/press/release/drain phase rechecks
context and the selected control/projection. Native control addresses identify
eligible controls; the extension never invokes their raw callbacks. Building
placement and unit orders retain original validation/command handling. Camera
pan owns local input flags and cancels on barriers. Stance uses the native
submission wrapper, not the internal stance mutator.

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
files and injected failures. Native task-only F-key diagnostics bypass physical
lookup because the current automation backend reports scan=0; they are never
keyboard-only acceptance and are excluded from product code. See the native
evidence documents for observed outcomes, mouse preparation and failed checks.

Remaining delivery gates include the full catalog/default/layout audit,
construction/economy/recruitment workflows, physical quicksave/load input, native profile
exchange/localization, packaging, command counts/performance, keyboard-only and
manual two-PC acceptance, Recorder replay/restore integration, review and normal
verified merge. Draft PR2 and issue1 remain open.
