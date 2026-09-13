# Store 3.0.7 preparation and cleanup

The module starts as soon as it is active in the launch configuration. There is
no separate enabled option and no launcher customization panel. F12 opens the
editor in supported contexts; Ctrl+Shift+F12 is reserved for recovery. Store
descriptions cover en/de/fr/es/hu/tr/ru/ch/fa. In-game text uses the UCP
loaded TextManager language marker with `data.version.getGameLanguage()` fallback
after `afterInit`. Eleven catalogs and the game's active codepage are supported;
native non-English font/language acceptance remains outstanding. The existing
text model now supplies character boundaries to clipping and caret layout.

`config.yml` requires only `ucp2-legacy.o_keys.enabled=false` when Legacy is
present. It adds no load-order entry or Legacy dependency. The GUI's standard
configuration merge creates the required lock; its serializer omits configuration
for extensions absent from the active resolved set. The existing runtime gate
also rejects incompatible imported/direct-launch configurations before enable.
No additional Legacy behavior is needed for these bindings. Legacy source is
unchanged. Native launcher integration still needs acceptance.

## Refactoring decisions

- Catalog/preset construction has one production factory shared by the framework
  and private LuaJIT state. Both states still own separate mutable objects.
- The profile store and exchange store share their codec and construction logic,
  while retaining separate transactional ownership and namespaces.
- Main-menu rendering/registration and active-menu reading are separate native
  adapters. Runtime now wires them together instead of embedding their details.
- Bindings compile into physical-key / owner / state lookups on Apply. The
  dispatcher still resolves current native facts, validates authority, and
  rechecks immediately before submission. No cross-event eligibility cache.
- Context identity field lists and the protected Windows observer are allocated
  once. Type annotations document binding and context contracts without a new
  runtime type system or dependency.
- Editor rows and profile lists already cache their view until it changes;
  text measurements and key labels retain their existing caches. Native controls
  are read from the active owner's array and rechecked before activation.
- Button rendering has one protected FFI callback. The obsolete nested protected
  closure and unused rendering locals were removed from each row; the native
  surface remains owned by the game. The menu reader also drops an unused manager
  argument/state. Existing editor, geometry, scrollbar and text checks pass (38).
- `files.xml` is the source of the installable payload for both builders. Only
  runtime code, definition, required configuration and README are installed.
  Test tools, investigations, screenshots and online descriptions stay outside
  the download. Sources remain readable; no minifier or bundled framework.

Necessary ownership, text/focus barriers, strict profile validation, double-slot
persistence, executable/ABI checks and error cleanup remain. These prevent actual
failure modes and are not removed to reduce line count. The native validation,
mouse input and synchronized command owners remain unchanged.

## Performance evidence and limits

A same-PC component benchmark on 12 September 2026 compared 092b787 with this
refactor, using 400 disjoint contexts sharing a key and 50,000 input messages.
LuaJIT tracing was disabled to match production callback policy. CPU time per
message fell from 10.30 to 2.12 microseconds (Lua5.4:26.08 to6.72). Text-owned
input remained blocked (LuaJIT0.62 to0.52 microseconds; Lua5.4 timings varied
1.02 to1.32). This synthetic worst-case lookup measurement excludes native FFI,
rendering, command submission and scheduler noise; it is not a game FPS claim.

The extension installs no simulation-tick callback. Its existing local-input
frame callback returns immediately while idle. It advances an active native
navigation/cursor/quickslot or held camera/lowering gesture, retires translated
mouse holds, and observes world lifetime while local bookmarks exist. It performs
no per-frame unit/building census. Grid work happens on keypress,
not each simulation step. Actual native 1100-speed, command-count and multiplayer
performance acceptance remains required; component results do not establish it.

Store publication and normal approved merge remain held for unfinished required
work and acceptance. The downloadable ZIP is explicitly a test build.

Native visual follow-up uses original Save/Load caption alignment and fixes a
real gameplay-only texture-target defect discovered during screenshot capture.
See [the editor evidence and native references](editor-layout.md).
