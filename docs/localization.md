# Game language and editor text

The framework's `data.version.getGameLanguage()` currently returns `english`,
`american`, `german`, `french`, `italian`, `SPANISH` or `polish`. The extension
normalizes that value and supplies editor, navigation and targeting labels for
all seven values. American English shares English labels. Building and native
control names use the game's own text lookup, including its native help table
mapping, rather than copied English asset strings. Launcher language is a
separate packaging integration requirement.

The verified SHC 1.41 font paths use code page 1252 or 1250. The extension reads
the active game code page and converts UTF-8 explicitly. Component checks prove
the supplied Western labels encode as 1252 and Polish labels as 1250, including
every current action. These checks do not establish font appearance or fluent
translation quality. Unknown patched font encodings are rejected at startup.
Additional language/font patches, RTL shaping, IME/DBCS input and non-Western
native layouts need their owner's encoding contract and native acceptance.

The editor measures text using the original font width function, clips long
labels to their controls and scrolls text fields to keep the real caret visible.
Selection bounds and layout are cached until the text, width or caret changes.
Keyboard labels are cached per Windows layout. This avoids repeating encoding
and key-name system calls every paint for unchanged text.

Pending: fluent review of new translations; actual native checks of all game
languages and supported keyboard layouts; minimum resolution/scaling; long and
RTL profile names; launcher option/conflict localization. No language acceptance
pass is inferred from source coverage or byte encoding alone.

Native PID29652 (SHC1.41, same verified dependencies as the building evidence)
opened the revised English editor at1280x720. The134-action list, layout-aware
German Windows key names and Swap keys button rendered without a Lua error;
mouse Cancel returned to the main menu. No profile was edited. This verifies
native rendering and close behavior, not capture/swap, long-field scrolling or
other language acceptance. The game closed normally; absence was checked and
the desktop released at18:12:10 CEST. Exact source hashes and logs are retained
in `layout-29652-build.json`, `layout-29652.log` and its error log.
