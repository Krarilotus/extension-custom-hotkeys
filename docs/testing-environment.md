# Native testing environment

Run a short input capability check before scheduling long gameplay acceptance.
A successful automation call does not establish that the game received the
physical key, text, focus change, or held gesture requested.

The current Windows Computer Use 26.901.51231 `@oai/sky` client can launch the
isolated game, navigate native menus with mouse clicks, press virtual keys and
change foreground focus. Its documented `press_key({window,key})` interface has
no scan-code, key-down/key-up, duration or hold-across-actions parameter. No
supported physical-input setting was found in the installed API documentation.
The bundled documentation does not include the backend implementation, so the
exact injection function and cause inside that backend remain unverified.

## Verified failures and recovery

On 11 September 2026, isolated game PID29788 received Return, W and `KP_Enter`
with lParam=1 on down and 0xC0000001 on up. Both Enter variants had scan=0 and
extended=false. The earlier PID30528 probe observed this before and after the
graphics wrapper, locating the missing identity upstream of that wrapper.
The values are consistent with virtual-key-only/message input, but do not prove
which backend API produced them. Escape was not used; its computer-use stop
behavior is a separate constraint.

The production adapter correctly forwards these unknown physical bindings.
Do not derive a pretend physical scan code in the product to make tests pass.
Windows specifies scan identity in lParam bits 16-23 and the extended flag in
bit 24 ([WM_KEYDOWN contract](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown)).

Caption-minimize clicks were ineffective. A supported alternative **worked**:
launch a task-owned Character Map window, explicitly activate it, then explicitly
activate the game. The native listener recorded focus=false followed by
WM_SETFOCUS/focus=true; generation advanced from 0 to 6. This establishes focus
transport, not held-key cancellation or gameplay acceptance. Do not use another
worker's app as the target. Close the owned focus window after the check.

An accessibility-only notice capture followed by an indexed click returned
`coordinate input geometry is unavailable`. Refreshing with a screenshot and
accessibility tree, then clicking the freshly observed button, succeeded. Use
one action and refresh; do not repeatedly click using stale geometry. The user
has authorized accepting the routine unsigned-extension developer notice.

## Minimum prerequisites

Before staging and again before requesting a desktop slot, run
`python tools/storage_preflight.py <isolated-install-directory>`. Require exit0
and at least2 GiB free on the installation volume. This read-only check does not
reserve space; still handle failed evidence writes by closing the owned app
normally and releasing. On 11 September, PID34292 encountered disk exhaustion,
and even the queue's atomic release failed until space returned. Its process
exited normally and release was verified20:00:25 CEST. Do not remove another
worker's files or call a truncated evidence run passed.

1. An unlocked interactive desktop, a fresh exclusive desktop-queue reservation,
   and an assertion immediately before each UI call. Release for background
   work and before ending the turn. Keep Escape available as the user stop key.
2. The isolated licensed SHC 1.41/UCP installation and exact dependency hashes
   recorded in [native evidence](native-input-evidence.md). Legacy hotkey patches
   OFF before activation. Preserve the baseline configuration and restore it
   after diagnostic runs. The input probe has no gameplay actions.
3. An input method that delivers real Set-1 scan identity, E0 distinctions,
   modifiers, separate down/up edges and held/repeated input through focus and
   screen transitions. This can be a scheduled human keyboard run or a supported
   corrected automation backend. A second PC is unnecessary for this check.
4. A task-owned focus target and observed native focus loss/return. No inference
   from screenshot appearance alone. Reacquire fresh window handles each run.
5. Close only the task-owned apps normally, verify their process IDs exited,
   save logs/build receipts and release the slot. Never leave test keys held.

For a transport check in the empty-action probe: press/release an ordinary key,
press/release main Enter and numpad Enter, hold an ordinary key long enough to
repeat and release it, then change focus away and back. Record the precise input
method separately. Do not hold a key with an automation interface that cannot
guarantee release on cancellation. The current documented client cannot perform
the hold step.

Run the read-only analyzer after releasing the desktop:

```powershell
python tools/input_preflight.py path/to/ucp3.log --transport 'exact method/version' --output receipt.json
```

Exit 2 blocks native keyboard acceptance; it reports observed failures separately
from missing coverage and records the log SHA-256. Exit 0 means only that minimum
transport evidence is present. It does **not** certify provenance of the input,
gameplay behavior, command counts, held-key transitions, AltGr/IME, localization,
multiplayer, replay, or performance. Use one complete probe session per log.
Keep the original log and build/config receipt beside the generated report.

## Backend correction needed

The desktop input backend owner needs a supported physical-key mode that
populates scan identity and preserves E0/key-up flags. Microsoft's
[KEYBDINPUT contract](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-keybdinput)
provides `KEYEVENTF_SCANCODE`, `KEYEVENTF_EXTENDEDKEY` and `KEYEVENTF_KEYUP` for
this purpose. Chords must retain real modifier state. A hold API also needs
bounded duration, cancellation cleanup and release of only its own held keys.
Verify the result at the target WndProc, including separate main/numpad Enter;
do not accept a successful backend return value as proof. This is a requested
backend contract, not a patch to inaccessible backend source or a hidden API.

The latest PID29788 receipt reports 8 zero-scan messages, no physical pairs or
repeats, and a successful focus round trip. Game PID29788 and Character Map
PID16852 exited normally; the queue was released at 14:34:31 CEST and baseline
configuration restored. No physical keyboard acceptance follows from this run.

Two-peer acceptance remains scheduled for the user's later manual run; see
[multiplayer checklist](manual-multiplayer.md). Recorder integration still needs
its owner's synchronous playback/state-restore boundary. Those are independent
of the input transport repair and remain required delivery gates.
