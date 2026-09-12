# Integration tester build 0.1.4

At the user's explicit request, Hotkeys no longer treats missing Recorder
integration acceptance as a reason to block startup or input. Multiplayer is
enabled, Recorder's version/API is no longer an activation requirement, and
Hotkeys no longer consults Recorder's `blocked` flag during playback, pause or
restore. Existing native game/control eligibility determines which actions run.

Recorder lifecycle notifications are optional. When present, they cancel old
held gestures at world transitions and provide a generation counter. Fresh
input is available afterward, including during playback. Without that API,
ordinary native screen/modal/focus transitions still apply. No Recorder code or
simulation pipeline is patched by this change. This build does not guarantee
read-only replay interaction; testers should report live-input/replay conflicts.

The known Legacy hotkey conflict remains resolved through the required
`o_keys.enabled=false` configuration. Text-entry ownership, actual visible
controls, native save/load availability and the SHC 1.41 native ABI still apply;
they define correct action routing rather than whether testing is permitted.
Mouse rebinding, building groups and camera bookmarks remain unfinished features,
not hidden functionality unlocked by this change.

The nine localized Store descriptions reflect this behavior. Component checks
cover absent/older/partial Recorder APIs, copied generation values and fresh
input after a transition reporting `blocked=true`. Earlier 0.1.2/0.1.3 replay
protection evidence describes those builds and is not a claim about 0.1.4.

486 component checks passed on Lua 5.4/LuaJIT; after removing obsolete activation
messages and updating descriptions, all 42 affected localization/module/metadata
checks passed again. Native multiplayer and complete feature acceptance remain
pending, without disabling the available implementation for testers.
