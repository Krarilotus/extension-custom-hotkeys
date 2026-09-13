# 0.1.9: reuse bindings across native panels

CIO reported that different game states still could not share one hotkey. The
catalog described all construction and unit controls as `game.build`, so its
conflict check and compiled router could not distinguish native panel ownership.

Controls now carry their native tab membership, derived from the original
screen14 menu table (including Granary's two panels). Unit stances use the same
61/62 panels already checked by their native action adapter. Validation and
routing use this shared catalog metadata. The existing scene supplies tab:subtab
identity; active native menu traversal and deferred native callbacks retain the
final visibility, enabled-state and command checks. There is no new hook,
framework API, runtime scanner, menu dispatcher or per-frame enumeration.

Woodcutter, Wheat Farm and Catapult can share a key. Woodcutter and Quarry cannot;
both belong to Industry. Global shortcuts still conflict with panel actions
where both are available. This does not invent priority between simultaneously
available buttons. Controls within one tab still conflict even if temporary
selection conditions hide one of them; a concrete reported pair is needed to
audit any finer native state distinction.

Binding capture, Apply, persistence/reload and runtime lookup share the same
rules. A held key crossing a panel change is quarantined until release. Existing
profiles remain valid; no binding or preset is silently reassigned. No new text
or localization keys were introduced; the eleven existing editor catalogs and
localized conflict messages remain in use.

Regression coverage includes actual production control bindings through editor
capture, profile reload, single dispatch, unit/build key reuse, same-panel and
global collisions, held transitions, text/focus/modal ownership and replay.
Native evidence and the exact public artifact receipt are in the Store preview.
Full original multiplayer/replay/state-restore acceptance is not claimed.
