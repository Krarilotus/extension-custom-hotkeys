# Recorder integration in development

Custom Hotkeys now uses Recorder's input lifecycle API version1 rather than
rejecting Recorder by name. Recorder remains optional. When enabled, it must
expose the verified API and finish startup before Hotkeys installs its hooks.
Recorder0.50.3 and older do not expose this API; the prerequisite implementation
is on `feat/custom-hotkeys-input-state`, based on Recorder PR46 commit02014385.

Each scene resolution reads current Recorder input ownership. Playback, paused
playback, loading, seek/restore, finished/error playback and unknown API states
disable custom dispatch. The synchronous transition observer invokes the same
router barrier used by focus loss, cancelling capture, pending clicks, quickslot
operations and owned camera/lowering holds before world replacement. Generation
also participates in context identity and quickslot tokens. Held input cannot
reactivate until a fresh press. No additional simulation/replay hook is installed.

Recording continues to accept native commands through the existing validated
path. Automarket1.1.0 retains its existing protocol1.0.0/map-extensions1.0.0
Recorder adapter. Its settings command is captured once; weekly simulation
trades must not be injected again by Hotkeys or Recorder.

Native combined acceptance is pending. Multiplayer command routing is being
audited; physical two-PC testing remains deferred to the user. This change does
not remove the existing live multiplayer gate or imply desync-free playback.
