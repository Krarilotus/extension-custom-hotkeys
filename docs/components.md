# Component contracts and outstanding integration

These modules do not install a hook or dispatch a game command by themselves.
The test catalog is deliberately confined to tests. No runtime compatibility or
native acceptance is implied by a component passing with an injected adapter.

`binding.lua` represents a Set-1 scan code, E0 flag and Ctrl/Shift/Alt bit mask.
Numpad and extended keys remain distinct. Modifier-only, E1/Pause, Windows and
reserved system combinations are rejected. AltGr/composition are native-owned.
Ctrl+Shift+F12 is reserved for a recovery entry whose native context must still
be proved safe; it is not a universal modal or text-input override.

`context.lua` requires explicit verified screen, panel, modal, control focus,
selection, targeting, state, authority and lifecycle generation. Unknown state
disables dispatch. It is a contract validator, **not the native resolver**.

`router.lua` tracks press/release ownership, consumes a remapped activation once,
suppresses its queued character messages and cancels local holds on barriers.
It rechecks context immediately before native dispatch. Reentrant routing is
consumed; uncertain native dispatch is never retried through the original key.
Capture is exclusive and cancels when its owner loses focus. A quarantined key
can recover after a missing release only when Windows reports a fresh down with
its previous-state bit clear. Tests for held transitions set that bit; duplicate
fresh downs without a barrier still cannot submit a second activation.

`messages.lua` preserves the next WndProc's arguments and return value. It uses
the supplied winProcHandler chain callback; it does not call GetMainProc or
simulate another keyboard message. Failure disables extension routing and
drains already consumed gestures before forwarding a fresh native press.

`preflight.lua` rejects enabled, missing, contradictory or non-normalized Legacy
hotkey settings. It must run at module load before native setup and again before
activation. The shipped UCP 3.0.7 `main.lua`, normalization and BaseLoader:load
phases were executed locally with instrumented extensions in both load orders:
Legacy ON failed before any enable call. This establishes the Lua load-order
contract only. Runtime integration, live byte checks and additional overlapping
Legacy options still need verification. Never attempt Legacy's unimplemented
runtime disable.

`native/win32.lua` checks the actual HWND's process/thread, foreground and focus;
reads queue-synchronized modifier down bits; preserves Right Alt/AltGr and IME;
and obtains distinct layout-specific key labels as UTF-8. The eventual view must
convert them to the verified game encoding. `native/interface.lua` uses UCP's
library service to resolve the documented winProcHandler C exports, avoiding the
table-return proxy failure tracked in
[framework issue #147](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/issues/147).

`native/chain.lua` pins one x86 stdcall callback in a dedicated LuaJIT state with
tracing disabled. It observes focus messages before graphicsApiReplacer, whose
continue-out-of-focus mode may consume them. Non-keyboard messages retain their
parameters and normal graphics conversion. It forwards the actual registered
priority and never retries an uncertain downstream native call.

These adapters have been exercised in a task-only native diagnostic with an
empty action catalog, not integrated with accepted gameplay actions or the
editor. See [native evidence and limitations](native-input-evidence.md).
Recorder activation currently fails closed pending its public input ownership
and lifecycle contract; native SP mode must not authorize live replay actions.

`profiles.lua` keeps edits in a draft and changes the active profile only after
persistence succeeds. Launcher bindings bootstrap a missing store; an existing
active profile wins on restart. Named profiles, import/export, unbind, reset and
atomic conflict reassignment are validated without executing imported content.
The schema remains developmental until the complete action catalog is frozen.

`store.lua` alternates two validated, checksummed files through an injected I/O
boundary. It preserves the previous good file on torn/failed writes, verifies a
new write by reading it back, and refuses ambiguous/corrupt state. Digests cover
generation and payload; they detect corruption, not authenticity. The UCP storage
adapter, codec, directory boundary and single-writer ownership are not wired yet.
Existing framework userdata work remains owned by UCP issue #131 / PR #142.

`editor.lua` provides shared keyboard/mouse operations, filtering and visible
row focus to a future native view. It is **not an in-game menu**. Native font and
encoding, text fields, rendering, mouse hit testing and localization remain open.

The tests cover injected failure paths and real temporary-file persistence in
Lua 5.4/LuaJIT. On Windows the test configuration disables CPython faulthandler's
SEH dump because LuaJIT uses that mechanism for caught Lua errors; assertions,
unexpected exceptions and process failures still fail normally. See
[LuaJIT error handling](https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_err.c).

Remaining completion gates include native action/catalog and lifecycle adapters,
placement and targeting, editor/localization, packaging and native SP tests,
manual two-PC tests, recorder integration and replay/restore, performance, review
and verified normal merge. The initial component stage does not close issue #1.
