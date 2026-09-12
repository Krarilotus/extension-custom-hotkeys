# Native bindings and button activation

The 0.1.5 refactor removes the executable SHA256 allowlist and all absolute
runtime game addresses. `address_bindings.lua` resolves named functions and data
through UCP's cached `core.AOBScan` and `utils.AOBExtract` during preparation,
before enable-time hooks. The UI dependency supplies its existing mouse state,
hit-test function and button surface. The dedicated LuaJIT state receives one
copy of these bindings; input dispatch performs no scans or per-binding remote
lookups. Active menu lookup still uses the UI manager's live API.

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

Focused sliders use their registered handler and native MenuItem slider state.
Event1 reads bounds/current value, event7 supplies the owner's increment, and
event2 submits one bounded change. The handler is queried again to reflect native
rejection or normalization. The field at +0x20 is thumb width, not step size;
using separate value buffers leaves the native thumb/label stale. This was traced
in MenuItem::handleMenuElementsCallbacks (reference0x4F45E1..0x4F48E8) and the
Gameplay Options handler, then reproduced in native PID30536. Research addresses
are evidence only; production uses the UI ABI and registered callback.

Explicit keyboard world targeting uses the native mouse-input adapter.
Traversal navigation can move the pointer to show focus;
direct building and Grid selection do not. Recorder input ownership notifications
and the shared winProcHandler chain remain in use. Legacy source is unchanged.

## Verification

The 0.1.7 editor follow-up uses the native display-element getter/setter for
world-hover element21. UI1.0.1's actual `ui/game.lua`, header and manager, and
Automarket's callers expose no display-element visibility API. The native
getter/setter bodies and Build-menu preparation calls were inspected: element21
uses enable values0/1, is local rendering state, and submits no game command.
UCP discovers both functions once; their full semantic patterns match uniquely
in both local fixtures. No render hook, copied display registry or polling is
added. Opening the editor remembers enabled visibility and hides only this
banner; closing/restoring ownership restores it only on the same screen and
Recorder input generation. A new world/view retains its own initialized state.
Native SHC PID7116 opened the editor with the banner hidden. Held-camera and
Save-name isolation checks are recorded in [the 0.1.7 evidence](features-0.1.7.md).
Native visibility restoration and the broader modal/focus matrix remain to be
verified; component checks cover same-screen restore and changed-world ownership.

The actual UCP AOBExtract utility resolved all 171 bindings against both local
Crusader 1.41 (`3bb0a8c1…`) and Extreme (`55648e6b…`) images. Each of the 155
scanned patterns had exactly one match in each mapped image; all reference
results equal the previously audited addresses. Three bindings reuse UI exports;
the remaining fields derive from their structure owners. Group stride, unit
capacity, tribe stride/capacity and selection-bitset length are extracted from
the original group-clear, tribe-clear and tribe-selection routines. Extreme uses
10,000 unit entries, 80,000 bytes per group, a 1,672-byte tribe stride and a
1,250-byte selection bitset; the corresponding Crusader values are 2,500,
20,000, 820 and 400. Both use 1,250 tribe slots. This is offline
resolution evidence, not complete native or multiplayer acceptance.

Component tests cover a relocated input hook, cursor-free activation exactly
once, callback re-entry, hidden/replaced controls, focus/text/modal changes,
physical mouse takeover and cancellation.

Native Crusader PID23876: F12 opened the Grid editor. A selected a keep without
moving the cursor (801,172); a normal click placed it. After placing a granary,
W changed category10 to20 and S selected woodcutter placement51; cursor(564,281)
and camera(2772,1864) were unchanged. Normal woodcutter placement reduced wood
45 to42. No mouse-button debt remained. Closed normally; desktop released.

First Extreme run PID27628: module initialization and F12 editor passed. F12
did not interrupt the native initial title field. Construction exposed a context
bug: modal130 is Extreme's nonblocking tactical-powers bar, not a modal dialog.
The shared background-layer predicate now recognizes that HUD only on world
screens; text fields and actual dialogs still retain input ownership.

Extreme retest PID33956, source `f4f56ec`: F12 opened the editor in gameplay.
With the tactical-powers HUD active, W changed category10 to20 and S selected
woodcutter placement51. Cursor(929,540), camera(224,2024) and all sampled mouse
button flags stayed unchanged. A normal click placed the woodcutter, reducing
wood100 to97. An earlier W during the AI message overlay (secondary modal19)
was rejected. The error log contained only its header. Both Recorder0.50.4 and
Automarket1.1.0 were loaded. Normal exit/PID absence verified; desktop released
15:10:11 CEST and configuration/profile baselines restored byte-for-byte.

The initial Crusader check used `0970e02`; the Extreme correction additionally
extracts layout sizes instead of assuming Crusader's smaller arrays. The exact
Extreme-tested ZIP is 94,158 bytes, SHA256
`5fabd7777d246aaf61ee99bc92a9b949e992a87723073fa23c6cef972258fe40`.
The corrected component suite passed 515 tests on Lua5.4/LuaJIT.
These checks do not establish full multiplayer, command-count, replay,
high-speed simulation or complete keyboard-only acceptance.

![Extreme gameplay editor](images/hotkeys-015-extreme-ingame.png)

## Reuse and remaining ownership boundaries

Inspected framework `02a7a6b`, UI1.0.1 `d3a807c` and winProcHandler1.0.0
`5f85672`. The tested installation uses UCP3.0.7-77c6a; its actual utilities
were used by offline verification. Separately owned branches were not edited.

| Capability | Existing implementation used / demonstrated boundary |
|---|---|
| Discovery/patches | Framework core.AOBScan/insertCode and utils.AOBExtract; data/cache.lua owns caching. No extension scanner or fixed-RVA fallback. |
| Windows input | winProcHandler RegisterProc/CallNextProc via core.openLibraryHandle; framework proxy limitation tracked in UCP3#147. |
| UI | ui/menu.lua, ui/modalmenu.lua, ui/game.lua, manager.lookupMenu; Automarket ui/automarket.lua demonstrates the same rendering and hit-test exports. |
| Button activation | UI MenuItem callback union/parameter; current enabled row invokes the original native handler. UI has no higher-level keyboard activation API. |
| Input frame/mouse | UI mouseState/isMouseInsideBox reused. UI1.0.1 has no before-input subscription or mouse-update/reset API. The single existing Hotkeys insertion uses UCP insertCode and preserves displaced instructions. A shared callback API remains an owner integration point. |
| Skin/text | Existing UI button/text/border exports. Table-cell rendering and text measurement are not exported; named native bindings supply those primitives. |
| Gameplay | UI has no save/load/camera/selection service; native handlers retain these responsibilities. No copied command executor. |
| Profiles | Framework normal-file io.open; two-slot recovery because it exposes no atomic replace. Separate userdata proposal: UCP3#142/#131. |
| Language | Framework data.version.getGameLanguage after native game initialization. |
| Replay | Optional Recorder observer/read contract in its separate owner PR; no copied loader, tick or restore implementation. Tester-mode input stays unrestricted. |

Final-diff review removed obsolete executable/identity adapters and production
reference-address literals. Simple building/category/Grid actions no longer use
positional click transport. Sliders use their native handler/state; traversal
focus and explicit world targeting use the native cursor adapter. Bindings resolve once before enable-time
patches and copy once into LuaJIT, with no input-frame scans or per-binding
remote lookups.

## Compatibility limits

Additional read-only verification used the official Firefly EFIGS and Polish
1.41 update executables already available in the workspace. The production
resolver and actual UCP AOBExtract resolved all 171 bindings; each of 155 patterns
matched exactly once in each mapped executable. Their code sections equal the
corresponding local Crusader/Extreme fixtures.

| Official fixture | Executable SHA256 |
|---|---|
| EFIGS Crusader | `0d3d0d0be90a41d0c07d02cb41e6edc3e399288d16039db5b666392660fbda34` |
| EFIGS Extreme | `70f083211e4260d877979e29bf5f5420aaa1c69fc5ee47057be458a84b5e6d0d` |
| Polish Crusader | `2aab6b3da99148b0796bd00a92b4b19db7548d1e2c50fa4372035f716fd33cab` |
| Polish Extreme | `e7e82625a39d3840bf44a84456967eeecafe7ec9d716afa67f1856ad59a9d460` |

Patch provenance and per-pattern results are retained in task evidence. No
installer was run and no other worker's installation was changed. Native
Hotkeys acceptance on these official executables remains outstanding.

Framework data/version.lua detects native version and Extreme markers; the module
declares SHC1.41 and SHCE1.41 rather than an exact file identity. The two local
PEs have bounded native evidence; the four official variants have offline binding
evidence. Other variants still need fixtures and native acceptance;
AOB matches alone do not prove compatibility.

The 0.1.8 source uses shared `core.AOBScanUnique`/`utils.AOBExtractUnique`
for all 155 patterns, including the input-frame hook and derived menu/stride
bindings. Missing or ambiguous results include the binding name; no addresses
are published and no extension hooks are registered before complete resolution.
UI exports remain owned by UI. No extension scanner, PE parser, cache, new
hook, fixed-address fallback or executable/Recorder activation lock was added.

This requires [UCP PR149](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/pull/149)
and [RPS PR16](https://github.com/gynt/RuntimePatchingSystem/pull/16). The prior
RPS scanner did not strictly respect bounds and could over-read a region from
an interior start. Its owner fix also handles boundary/overlapping matches and
provides bounded first/second matches in main-image executable pages. UCP owns
cache updates and the unchanged operand/capture decoder. Do not publish 0.1.8
as a standalone stock-3.0.7 ZIP or claim the prerequisite has shipped.

Correction to the earlier fixture audit: its non-overlapping regex missed a
second overlapping `playerLord` signature. In Crusader, starts 0x40FCE7 and
0x40FD18 captured different player fields; Extreme has the same instruction
sequence shifted by 0x10. The signature now includes the next short conditional
branch, distinguishing the intended lord field from the following reset block,
with relocatable operands still wildcarded. The read-only verifier now includes
overlapping matches. Historical 0.1.7 uniqueness claims are superseded by this
finding; previously recorded native gameplay observations remain separate.
