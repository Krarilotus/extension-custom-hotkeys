# Game language and editor text

The loaded TextManager's language marker (text group6, entry0) selects the
editor language. This includes translated installations whose executable still
reports its original language. Unknown markers fall back to the framework's
`data.version.getGameLanguage()`, then English. American English shares English
labels. Catalogs cover English, German, French, Italian, Spanish, Polish, Russian,
Hungarian, Turkish, Chinese and Persian. Building and native control names use
the game's own text lookup, including its help table mapping. Store descriptions
separately cover all nine Store3.0.7/GUI catalogs (en,de,fr,es,hu,tr,ru,ch,fa), with
opening instructions, automatic activation and optional Legacy conflict
resolution. Changing the GUI language does not change the in-game language.

UI1.0.1 exports the active TextManager and native text getter/renderer but no
language or conversion service. Its actual implementation and Automarket callers
were inspected, together with Recorder's existing language-marker/codepage
handling. The extension reuses these UI primitives and its existing Windows
conversion adapter; Recorder remains optional and supplies no duplicated text
service here. No new hook or game binding is added for language selection.

The two-codepage startup restriction is removed. The loaded TextManager owns
the codepage, including translated fonts. UTF-8 is converted explicitly through
Windows; invalid input and lossy best-fit conversion are rejected. Persian yeh
maps to Arabic yeh only for Windows-1256, matching the game's font encoding.
Tests exercise production conversion through actual Windows APIs for 1250,
1251, 1252, 1254, 1256, 936, UTF-8 and GB18030, including roundtrip and rejection.
Catalog checks cover every current action and language without English fallback.
These checks do not establish font appearance or fluent translation quality.

The editor measures text using the original font width function, clips long
labels to their controls and scrolls text fields to keep the real caret visible.
Clipping uses the existing UTF-8 editor character model before conversion,
preserving DBCS/UTF-8 boundaries and character-indexed caret/selection positions.
An unrepresentable character displays as `?` without corrupting stored UTF-8.
Selection bounds and layout are cached until the text, width or caret changes.
Keyboard labels are cached per Windows layout. This avoids repeating encoding
and key-name system calls every paint for unchanged text.

Pending: fluent review of new translations; actual native checks of all game
languages and supported keyboard layouts; minimum resolution/scaling; long and
RTL profile names and shaping; native IME/DBCS text input; fluent review of Store descriptions. No language acceptance
pass is inferred from source coverage or byte encoding alone.

Native PID29652 (SHC1.41, same verified dependencies as the building evidence)
opened the revised English editor at1280x720. The134-action list, layout-aware
German Windows key names and Swap keys button rendered without a Lua error;
mouse Cancel returned to the main menu. No profile was edited. This verifies
native rendering and close behavior, not capture/swap, long-field scrolling or
other language acceptance. The game closed normally; absence was checked and
the desktop released at18:12:10 CEST. Exact source hashes and logs are retained
in `layout-29652-build.json`, `layout-29652.log` and its error log.
