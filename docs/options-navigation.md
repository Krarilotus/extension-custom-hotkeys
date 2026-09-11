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
+0x24. Rendering/input at `0x4B0F0E` reads that pointer, writes the menu's actual
rendered x/y, then calls native menu input and rendering. Individual controls can
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

Options now derives its origin from the active composition's x/y plus the
native viewport offsets at `0x21AEC58/5C`, following `0x4B0B93..0x4B0BBE`.
Border bit2 adds the twelve-pixel top strip (`0x4B0CB4..0x4B0CDE`). It requires
an idle, non-closing composition and a bounded rectangle, and applies this
origin only to controls owned by the verified active menu. No native geometry
is written or cached across frames. The click guard still rechecks the active
layout and native hover. This second correction requires a native retest.

In PID2564, mouse fallback opened Save/modal10/text index2. A diagnostic rotate
attempt logged no eligible context; rotation0, zoom0, camera2772/1864 and all
pan hold flags0 stayed unchanged. This is a native text-modal rejection check,
not typed-text or physical held-key acceptance. The process closed normally,
absence was verified, and the desktop was released19:54:25 CEST.
