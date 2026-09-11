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
rendered x/y, then calls native menu input and rendering. Navigation reads those
coordinates and sends its guarded gesture through original mouse processing.
It does not call a button callback directly.

Paused0/1 is allowed only for this verified options owner; all other world,
authority, session, focus and transition guards remain. Changing modal identity
changes the context generation and cancels a pending gesture. Save/load and
name-entry dialogs remain excluded until separately verified.

Component checks cover the positive owner and wrong active pointer/ID, text
entry, covered modal, focus/IME, multiplayer and transition rejection, including
denial of world actions. Native options navigation acceptance is pending.
