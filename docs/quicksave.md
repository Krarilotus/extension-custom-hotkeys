# Quicksave through the native Save owner

`game.quicksave` defaults to Ctrl+S and uses the dedicated native save name
`Custom Hotkeys Quick`. The existing Alt+S signpost action remains configurable
as the replacement for original S aliases. Quickload remains separate work.

One fresh activation opens the normal Save dialog via the existing guarded action.
A bounded workflow sets native name entry2 using0x469800 and introduces one Return
through UserTextHandler0x469870. The ordinary Save menu item0x494920 consumes it,
then the normal button owner0x4943B0 performs filename/file-existence checks. For an
existing slot, only exact overwrite modal11/menuB97AD8/operation30/name match
permits native hit-tested Yes22. That owner routes to progress14/operation32;
the extension never calls the progress callback, serializer or world mutator.

Eligibility reuses shared native session validation and locks screen, mode,
player, SP synchrony, focus generation and viewport size for the workflow. Save's
editable text field never becomes a gameplay/navigation context. The private
cursor context exists only for the proven non-editable overwrite confirmation.
User typing, a real pointer gesture, IME/focus/owner transitions or unknown state
cancel the workflow. A consumed trigger's release remains suppressed. Cancellation
clears only the Return flag introduced by this workflow and any owned cursor edges;
it never manufactures a release on a new screen. Uncertain commits are not retried.

The existing input-frame callback advances pending work and returns immediately
when the cursor/camera/workflow are idle. There is no new global hook, disk polling,
private serializer or copied native save implementation. The90-frame lifetime is
a failure bound, not a repeating save timer. Saving/overwrite errors remain owned
by the native UI. Active MP and Recorder are still rejected by existing integration
gates. Component tests cover first save, overwrite, single submission, cancellation,
foreign dialogs/names, session/focus changes and pending Return ownership.

Native first-save and overwrite acceptance is pending. Full physical keyboard-only,
held-key, multiplayer and replay/state-restore acceptance remains incomplete.
