# Native input transport investigation — 11 September 2026

This is limited diagnostic evidence, **not Custom Hotkeys acceptance**. The
isolated probe had no action catalog, rejected every context and could not issue
gameplay commands. There is still no installable product artifact or completed
keyboard-only workflow.

Reference: SHC 1.41 executable SHA-256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`,
UCP 3.0.7 revision `77c6accf14a55fb95434fe6ffd96516e005568b5`, official
winProcHandler 1.0.0, graphicsApiReplacer 1.3.0 and luajit 1.0.0. Legacy,
Recorder and other gameplay extensions were inactive. The official LuaJIT
initialization/remote-interface source and winProcHandler `init.lua` matched the
audited checkouts after line-ending normalization.

The actual C-export chain installed and forwarded native mouse/menu and text
input. Windows reported `A`, `EINGABE` and `EINGABE (ZEHNERTASTATUR)` for physical
A, Return and E0 Return labels on the current German layout. Shift/Ctrl/Alt down
bits were observed as 2/1/4; ordinary key events as 0. Other layouts, AltGr, IME,
held gestures and physical binding activation have not passed native acceptance.

Two native runs observed the description route through Custom Scenarios > New
Map > New Crusader Map > 160x160 > Edit. Screen 17/modal 25 showed textIndex 9,
textActive(+4)=1, allowUserTextInput(+0xC)=0 and TextEditorInitialized=1. After
native Exit, modal 25 closed and TextEditorInitialized cleared, but textActive
remained 1. Neither imported flag alone identifies actual current text focus.
In the baseline without this probe, individual automated presses rendered
`wasd`; with the chain, `w` and Shift+A rendered `wA`. Bulk `type_text` rendered
nothing. Ctrl+A was forwarded without changing that text. These observations do
not reproduce or clear the reported Legacy hotkey bug.

The automation's keyboard events contain no physical scan code. A diagnostic
listener before the graphics wrapper observed W as `WM_KEYDOWN`, wParam=87,
lParam=1 and its release as lParam=0xC0000001. Shift and A likewise had scan=0.
The listener after the wrapper observed the same values. This is not specific
to Escape; the user noted Escape also stops computer use. Unknown scan codes
remain native-owned; the router does not invent a physical binding from them.
Required native binding/held/layout acceptance needs valid scan-code input,
either a supported automation path or a scheduled human keyboard run.

The diagnostic's successful product callback was at priority 0; its additional
raw observer was at -100001. Subsequent source audit found that graphics
continue-out-of-focus mode consumes/rewrites focus messages, so the production
listener now requests -110000 and requires a returned priority below -100000.
PID15848 subsequently verified installation at -110000 and normal native input
forwarding. Attempts to minimize via caption coordinates and the exposed native
control did not minimize the window or emit focus-loss events; focus-transition
acceptance therefore remains unperformed.
No second Windows hook or graphics source change was introduced.

Follow-up PID29788 verified a focus round trip by activating a task-owned
Character Map window and then the game. Numpad Enter still arrived without scan
or extended identity. The new read-only input preflight reports that transport
failure before gameplay acceptance. See [testing environment](testing-environment.md)
for the corrected focus procedure, geometry recovery and backend requirements.

Earlier failed probe launches are retained in the task records: missing LuaJIT
debug configuration, unavailable Lua API in winProcHandler 0.2.0, and framework
table-return proxy failure with 1.0.0. The latter also reproduces with the shipped
Lua source and is tracked in
[framework issue #147](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/issues/147).
The documented C exports provided the verified continuation path.

All games were closed normally and process absence checked before releasing
each desktop slot. Last diagnostic PID 15848 exited; slot released 14:10:54 CEST.
Raw logs, build/config checksums and samplers remain under the task's
`Roadmap/Investigations/Custom-Hotkeys/native-evidence/` directory. Diagnostic
logging adds overhead; no native performance claim follows from this run.

Windows contracts used:
[queue-synchronized keyboard state](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeyboardstate),
[physical key labels](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeynametextw).
