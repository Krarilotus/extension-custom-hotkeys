# Existing building shortcuts

Development implementation; native acceptance remains pending. These shortcuts
open an existing local player's building through the original status opener
0x463310. They do not choose a building for placement, recruit or trade by
themselves. Those operations use the active panel's native controls.

| Building | Focus and open | Open panel | Return to previous view |
|---|---|---|---|
| Keep | H | Ctrl+H | Shift+H |
| Granary | G | Ctrl+G | Shift+G |
| Armory | Alt+A | Ctrl+A | Shift+A |
| Barracks | B | Ctrl+B | Shift+B |
| Market | M | Ctrl+M | Shift+M |
| Engineers' Guild | I | Ctrl+I | Shift+I |
| Tunnelers' Guild | T | Ctrl+T | Shift+T |
| Mercenary Post | N | Ctrl+N | Shift+N |
| Stockpile | — | Configurable, initially unbound | — |

These development defaults use the reference letter positions. Layout mapping
and the complete original-key inventory are still acceptance gates. Shift takes
precedence over Ctrl in the original branches; Ctrl+Shift aliases are therefore
tracked as return actions in conflict detection. Armory focus moves to Alt+A to
make room for the WASD pan replacement.

The reference WndProc branches are H0x4B3954, M0x4B3A4F, B0x4B3C02,
I0x4B3CBA, T0x4B3E70, N0x4B3F38, G0x4B4000 and A0x4B40C9. Each first
tests repeat, game/menu eligibility, then Shift and Ctrl. Focus obtains the
viewport tile through0x4B2A60, stores its own native bookmark, focuses building
coordinates plus(2,2) through0x4E8CA0, then opens its panel. Return uses0x4E5E20,
returns screen16 to screen14 through0x46B340, and clears only that bookmark.

`code/building_actions.lua` records the corresponding player ID field and native
bookmark address. Building categories/types and the40-byte player entries are
cross-checked with the original table/branch and OpenSHC's PlayerData/BuildingType
declarations. The stockpile has no audited original focus/return shortcut;
its new configurable panel action uses the same existing status opener.

Every adapter resolves the current screen/modal/focus/session again and rejects
missing, reused or foreign building IDs. Focus also validates coordinates and
the return tile. Native panel validation remains in charge of opening the
interface. Camera bookmarks are native local UI data; no simulation fields,
resources or commands are written by these adapters.

Component tests cover separate bookmarks, open without camera movement, return,
ownership/type rejection and modal/text/state changes. Required native checks:
each available building and keep variant; unavailable/destroyed/reused building;
panel open/focus/return; correct localized label; no duplicate action on repeat
or release; covered/hidden panel rejection; native mouse operation afterward.
