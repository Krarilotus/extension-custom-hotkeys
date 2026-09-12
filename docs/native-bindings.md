# Native bindings and button activation

The 0.1.5 refactor removes the executable SHA256 allowlist and all absolute
runtime game addresses. `address_bindings.lua` resolves named functions and data
through UCP's cached `core.AOBScan` and `utils.AOBExtract` during preparation,
before enable-time hooks. The UI dependency supplies its existing mouse state,
hit-test function and button surface. The dedicated LuaJIT state receives one
copy of these bindings; input dispatch performs no scans or remote address reads.

Native structure fields retain their ABI offsets. The viewport rectangle offset
is extracted from the original setup function; menu arrays are extracted from
their constructor calls. No address is inferred from a whole-image relocation
delta, and no reference-address fallback is used when a signature is absent.
The obsolete filename, working-directory and whole-file hash checks are removed.

Building/category/Grid shortcuts queue the active enabled control's existing
cdecl callback and parameter. At the input frame, ownership and control identity
are checked again. The pending action is cleared before entering game code, so
callback re-entry cannot submit it twice. No placement ID is written and no
mouse gesture is generated for simple buttons. The original toolbar handler
retains tutorial, player and game-state validation; actual placement still uses
the normal native validated command path.

Positional sliders and explicit keyboard world targeting still use the native
mouse-input adapter. Traversal navigation can move the pointer to show focus;
direct building and Grid selection do not. Recorder input ownership notifications
and the shared winProcHandler chain remain in use. Legacy source is unchanged.

## Verification

The actual UCP AOBExtract utility resolved all 164 bindings against both local
Crusader 1.41 (`3bb0a8c1…`) and Extreme (`55648e6b…`) images. Each of the 150
scanned patterns had exactly one match in each mapped image; all reference
results equal the previously audited addresses. Three bindings reuse UI exports;
the remaining fields derive from their structure owners. This is offline
resolution evidence, not complete native or multiplayer acceptance.

Component tests cover a relocated input hook, cursor-free activation exactly
once, callback re-entry, hidden/replaced controls, focus/text/modal changes,
physical mouse takeover and cancellation. Native testing is in progress.
