# Profiles and transfer

Open Custom Hotkeys from the main menu, F12, or the reserved Ctrl+Shift+F12
recovery chord while an eligible menu/game screen is active. Recovery does not
override native text fields, another modal or an unsupported session.

Choose New profile, type its name and press Enter. Select an action and Change
key to capture its new binding. Clear key unbinds it. A conflict preserves both
bindings and offers Swap keys; the swap is atomic and still rejects collisions
with a third action or a native action left without a required replacement.
Reset action and Reset profile affect only the draft. Apply saves and activates
the draft. Cancel discards it. Reset the profile for familiar development defaults.

The selected saved profile wins over launcher bootstrap defaults on restart.
Normal settings use `ucp/custom-hotkeys-profiles-a.json` and `-b.json` inside this
game installation. Alternating checksummed files preserve the previous good
version if a write fails. Another game installation has its own settings.

Export profile writes the currently selected draft profile to a separate pair:

- `ucp/custom-hotkeys-exchange-profiles-a.json`
- `ucp/custom-hotkeys-exchange-profiles-b.json`

After the first export only `-a.json` may exist. Transfer the complete exchange
pair to the other installation's `ucp` folder, retaining a backup of any existing
exchange files and replacing the pair together. Do not mix one source file with
one destination file: the importer chooses the newest valid generation. Settings
files are separate and must not be replaced for a profile transfer.

In the destination editor, Import profile reads the exchange files and asks for
a new, unused profile name. Enter accepts the name into the draft; Apply is still
required to save/activate it. Cancel discards the imported draft. Imported data
is size-limited, checksummed, parsed as JSON and validated against the action
catalog. It is never executed. Export does not implicitly Apply the draft.

The schema/action catalog is still developmental; transfer currently requires
matching catalog revisions. A mismatched/corrupt or unreadable pair is rejected
without replacing the active profile. Human-readable diagnostics and native
import/export acceptance remain under development. File round-trip and failure
recovery component tests do not establish the native acceptance gate.
