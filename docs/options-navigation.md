# Active options navigation

The ordinary single-player options dialog now has its own `game.options`
context. Tab, Shift+Tab and the configurable gameplay-control activation can
navigate its actual active menu. Camera, building, targeting, unit and hotkey
editor actions have no permission in this context. Multiplayer remains gated.

The SHC1.41 reference executable (SHA256
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`)
constructs menu `0xB971F0` at `0x59AD80`: eight buttons, no text field.
Native modal activation `0x4A9ED0` copies the selected composition entry.
The resolver requires modal5, text-modal5, active-copy ID5 and that exact menu
pointer, plus no second/third modal or active text editor. It never obtains an
options menu from the registry while a different modal owns input.

The active composition is at `0x1FE7C90`; its ID is at +4 and menu pointer at
+0x24. The input update at `0x4AA311..0x4AA327` copies the active composition's
client x/y to its menu before calling `0x4F6470`. Rendering at `0x4B0F0E`
overwrites that origin with offscreen viewport offsets. Individual controls can
retain a different owning Menu while sharing that array. Input at `0x4F4333`
and rendering at `0x4F4A26` use the item's owner pointer at +0x4C. Navigation
therefore reads that owner's coordinates and verifies its array. Shifted menus
are rejected: rendering subtracts owner+0x14 but this input path does not.
Navigation sends its guarded gesture through original mouse processing.
It does not call a button callback directly.

Paused0/1 is allowed only for this verified options owner; all other world,
authority, session, focus and transition guards remain. Changing modal identity
changes the context generation and cancels a pending gesture. Save/load and
name-entry dialogs remain excluded until separately verified.

Component checks cover the positive owner and wrong active pointer/ID, text
entry, covered modal, focus/IME, multiplayer and transition rejection, including
denial of world actions. PID20256 exposed the previous coordinate error: Save
was targeted at788,223 instead of638,208, and the native hover guard cancelled
the click. No save action occurred. The owner-coordinate correction has
component coverage. Its PID2564 retest still targeted808,231: the item points
to the same menu, whose coordinates change between native processing passes.
The hover guard again cancelled without a click. Reading the owner alone
therefore did not fix Options navigation.

Options derives its input origin directly from the active composition's x/y.
The viewport offsets at `0x21AEC58/5C` belong to rendering, not client input.
Activation initializes the idle animation value to32 (`0x4AA057`); zero belongs
to an opening animation when border bit0x400 is set. Navigation requires32,
non-closing state, the verified Options border0x200 and a bounded rectangle.
It applies this
origin only to controls owned by the verified active menu. No native geometry
is written or cached across frames. The click guard still rechecks the active
layout and native hover. Native retesting of these input-coordinate and idle
corrections remains pending. PID34292 rejected navigation because the previous
version incorrectly required animation0. Its read-only sample confirmed
modal388,116,504x360, border512, animation32, closing0, versus render offsets
170,24 and Menu origin558,140. Disk exhaustion truncated file evidence, so the
sample survives only in the tool transcript; no acceptance pass is claimed.

In PID2564, mouse fallback opened Save/modal10/text index2. A diagnostic rotate
attempt logged no eligible context; rotation0, zoom0, camera2772/1864 and all
pan hold flags0 stayed unchanged. This is a native text-modal rejection check,
not typed-text or physical held-key acceptance. The process closed normally,
absence was verified, and the desktop was released19:54:25 CEST.

The corrected input-origin implementation passed its native adapter retest in
PID16852 on11 September21:31 CEST, production revision bed43db. From a
mouse-prepared Castle Builder fixture, F9 selected Save at client638,207 with
visible native hover. F8 activated it through the normal cursor/input path;
Save/modal10 opened, and the remaining gesture cancelled on the owner change.
F10 rotation was rejected in Save, with camera2772/1864, rotation0, zoom0 and
pan flags0. Native `w` appeared in the focused name field. Nothing was saved.
Game exit and absence were verified; desktop released21:32:13; baseline restored.
Receipts: workspace `native-evidence/options-16852-{build.json,before.json,
save.json}` and `options-16852.log`/`options-16852-error.log`.
The task-only F-key diagnostic bypasses scan0 transport. This verifies native
navigation/activation and text-modal isolation, not physical rebinding, held
keys, command counts or the complete keyboard-only acceptance route.
