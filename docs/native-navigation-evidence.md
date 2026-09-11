# Native menu navigation development check

11 September 2026, isolated GamerGrill process 4184. Reference SHC 1.41 SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`,
UCP 3.0.7, graphicsApiReplacer 1.3.0, UI 1.0.1. Legacy and recorder inactive.
Before native addresses are used, the extension verifies the process module,
base address, matching working directory and executable content hash.

The task-only F9/F8 diagnostic invokes production menu action adapters; it does
not simulate physical scan codes or establish the configurable-key acceptance
gate. The automation backend still reports scan code zero.

Observed route:

1. Return advanced startup to screen 41.
2. Next moved the visible cursor to Crusader. Native axe hover and help appeared.
3. Next moved to Historical Campaigns, with the corresponding native hover/help.
4. Activate opened the campaign selection screen. A read-only sample confirmed
   screen 42, transition delay -1, all three modal slots -1, mouse (561,274),
   and left button held state zero.
5. Alt+F4 closed the isolated process normally; PID absence was checked. The
   desktop slot was released and the isolated baseline configuration restored.

The implementation traverses only the current native menu's eligible controls.
It moves the visible cursor with the game's graphics scaling geometry, then
lets original mouse input processing perform hover/hit testing and activation.
The bounded gesture has aim, press, release and drain phases. Each phase
revalidates context; changed controls, physical input and transitions cancel it.
No raw menu action pointer is called. No simulation or world data is written.

A first development attempt updated native mouse coordinates without moving
the visible cursor. Normal WM_MOUSEMOVE restored the old location and correctly
cancelled navigation. The visible-cursor adapter fixes that failure; the successful
route above used it. Development logs and exact per-file build hashes are stored
under `Roadmap/Investigations/Custom-Hotkeys/native-evidence/navigation-4184*`.

The current allowlist covers main, custom-scenario, campaign and mission menus.
Gameplay, placement, targeting, arbitrary modals, minimum-resolution/scaled
native checks, command-count instrumentation and complete keyboard-only,
multiplayer and replay acceptance remain pending. This result must not be used
as evidence for those unperformed checks.
