# Packaged module native check — 11 September 2026

PID33000 loaded the isolated development ZIP built from commit
`432cf02858cf9b5116c6d39e43e38af155ad1eb0`. ZIP size: 91,867 bytes; SHA256:
`e8447656095ea71dcdac065a29fb3cb28401a230a75f08f5dc738eff9cbfc7c3`.
SHC1.41 executable SHA256:
`3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a`.
UCP3.0.7-77c6a, UI1.0.1, LuaJIT1.0.0, cffi1.0.0,
winProcHandler1.0.0 and graphicsApiReplacer1.3.0. Configuration SHA256:
`4ac2d53c001fae9047c765585caa9a5d1e32dff0a9f0b13ef2f6e7451888c18b`.
Legacy, Recorder and diagnostic modules were absent from the active configuration.

The ordinary unsigned-development notice was accepted as authorized. The
framework loaded/enabled custom-hotkeys0.1.0 and reported installed=true,
modal2041, priority-110000, profile Default. From the visible main-menu entry:

- Mouse opened the real editor. Six rows and the 157-action count rendered;
  action labels and right-aligned bindings stayed in separate columns.
- New profile accepted logical text `p` and Return. Export reported success.
- Import read that export and selected its existing name; typing `i` replaced
  the selection. Return created draft profile `i`.
- Cancel returned to the main menu. Neither active profile storage file was
  created. The independent exported profile file remained, as intended.

Native fonts were English with Windows German key names (TABULATOR/EINGABE).
The main-menu entry also showed a large outlined rectangle beneath its label;
the later native table audit identified this as original help item1
(menu-local155,490,335x85, renderer0x4F6A60). A localized hover description now
uses that area; its native appearance still needs verification. Minimum resolution,
other native languages and physical key capture were not tested here.

Normal Alt+F4 closed the game. Process absence was verified, desktop released
at19:17:43 CEST, and the isolated baseline configuration restored. Task-local
receipts are `native-evidence/package-33000.log`, `package-33000-error.log`,
`package-33000-exchange-a.json`, plus `package-test-build.json` and
`package-test-config.yml` under Roadmap/Investigations/Custom-Hotkeys.

This verifies development ZIP activation and this mouse/logical-text editor
route only. It is not physical keyboard-only, gameplay, MP, replay, complete
package acceptance or release approval. The current input backend supplies
scan0, so it cannot establish those physical binding or held-key checks.
