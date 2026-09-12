# Two-PC Custom Hotkeys acceptance

Status: **not run; deferred to the user**. No second computer or `replay-peer`
desktop ownership is assumed. Obtain that PC's actual testing owner and queue
before testing. One person should own input on each PC for the entire short run.

Do not start this checklist until the extension has an installable, identified
artifact and the single-PC keyboard route has passed. The current preview still
rejects live multiplayer dispatch. Record failures without changing acceptance to pass.

## Freeze the test environment

Record both PC names, executable SHA-256, extension commit and ZIP SHA-256,
framework/UI/winProcHandler/recorder versions and hashes, full normalized launch
configuration, map/save hash, resolution, game language and keyboard layout.
Legacy `o_keys.enabled` must be exactly false on both peers before launch.
Do not enable Legacy and Custom Hotkeys together to obtain a baseline.

Use identical simulation settings and different **local** hotkey profiles. Give
profile A and B different bindings for the same build choice, market/recruitment
operation and unit order. Save/export both profiles and record their hashes.
Preferences must stay outside synchronized world/save data. Editing a binding
must not change the simulation configuration or require the other peer to rebind.

Use a prepared, saved scenario with enough resources, an available market,
recruitment building and controllable units for each player. Specify an empty
legal building location and a rejected location. Fix both target locations and
the intended unit selection before comparing mouse and hotkey submissions.

## Run the cases on host and client

| Case | Input and observation | Required result |
|---|---|---|
| MP-01 | Open local settings, create/select another profile, rebind, cancel, apply; other player observes the game | Local settings do not independently pause, advance or modify simulation. Cancel preserves active bindings; apply changes only that PC's preferences. |
| MP-02 | Choose the same building via its native control and the configured action in equivalent prepared states; move keyboard target, rotate if supported, confirm | Same validated native command batch and outcome. Both peers receive it once. No mouse fallback. |
| MP-03 | Hold placement confirm; try occupied/unaffordable location; cancel placement while confirm is held | No repeat spending or delayed placement after cancel. Native rejection/repeat-placement behavior matches the mouse baseline. |
| MP-04 | Navigate market, choose a good, trade once, hold the trade key; cover and close market and press the same key | One intended transaction; native eligibility and resource rules apply. Covered/closed market receives no transaction. |
| MP-05 | Navigate recruitment, recruit once, hold key; repeat with insufficient resources/peasant availability | Same accepted/rejected result and command batch as native control; no held-key spending loop. |
| MP-06 | Select/cycle units and groups; specify movement and attack targets using keyboard; repeat for owned, allied and enemy objects | Native selection/authority rules preserved. Commands apply to the intended authorized selection on both peers. No direct world mutation. |
| MP-07 | Type `wasd WASD`, actual bound characters, names, modifiers and layout-specific text in lobby and chat; hold a key entering/leaving each field | Characters and native editing work; no camera movement, trade, recruitment, build or unit order. Releasing/holding through transition emits nothing. |
| MP-08 | Cover gameplay with each available modal, change selection/targeting context, lose/regain focus with keys held | Only the current screen/control owner receives input. A new press is required after transition. No duplicate or delayed batch. |
| MP-09 | Invoke configured quicksave/quickload from MP, then test the game's supported host save/load continuation with both peers | Unsupported SP quick paths reject. Supported continuation uses the existing session owner, with peer agreement and no stray held-input commands across load. |
| MP-10 | End normally; restart with the same installation and resume a second short run | Both local profiles persist independently; no stuck keys or changed simulation configuration. |
| MP-11 | Enable Automarket 1.1.0 with protocol/map-extensions 1.0.0 on both peers; commit one policy per player, let a weekly trade occur, then restore/replay | Each 272-byte commit is attributed to its owning player and captured once. Both peers reproduce the same policy, fee and resource changes. Weekly trades are simulation work and are not injected a second time. |

For an action that natively submits one command per selected unit, compare the
**whole native batch once**. A blanket assertion of one packet per key would
incorrectly reject legitimate multi-unit orders. Record attempted activations,
accepted/rejected native actions, submitted batch contents, scheduled ticks,
player IDs and executed command counts. Capture idle windows around each action
to detect commands produced on release, repeat or transition.

## Compare evidence using the recorder owner

Preserve complete host/client capture folders, manifests, command journals,
environment sidecars, initial world/RNG evidence and final outcomes. Use the
recorder version's own inspector/comparator and retain the full output and exit
code. Do not remove uncovered events, fabricate an ending or normalize away a
player/category/payload mismatch to obtain a pass.

Compare agreed simulation checkpoints at the same ticks, before and after each
workflow and after load continuation. Preserve native world-hash observations,
RNG/resource evidence and visible building/unit/resource outcomes. Recorder
`state-digest-v1` hashes RNG plus resources; equality alone is **not complete
world-state proof**. The inspected owner code is PR #46, commit
`02014385ce05b002764c9c4f658e5eb6b98c125e`; recheck its actual accepted build before
running. Older stage-one documentation does not establish current playback support.

## Replay and restore

The recorder must expose input-state API version1. The prerequisite implementation
is [Recorder fork PR2](https://github.com/Krarilotus/ucp_recorder/pull/2), stacked
on upstream PR46. See [bounded SP evidence](recorder-integration.md); it is not
a two-peer or complete Hotkeys acceptance pass.
Do not add a competing recorder load/tick/seek hook to run these tests.

Record representative hotkey workflows. Play with a different profile, including
an unbound former action key. Compare recorded commands and checkpoints/final
outcome. During playback, pause, finish/error states, forward/backward seek and
state restoration, press and hold every world-changing binding, then release.
No live world-changing batch may be submitted; history must never be interpreted
as keys. Exercise keys held before entry and across exit/load/restore; verify
pending gestures are cleared. Test only local viewer actions explicitly owned
by the recorder. Repeat on supported offline multiplayer playback once its own
prerequisites pass. An unavailable capability remains a blocker.

## Result record

For every case record `not run`, `pass`, `fail` or `blocked`, operator/date,
artifact IDs, input steps, tick/sequence boundaries, observations and evidence
paths. Record every mouse fallback. A comparator's incomplete result, unsealed
capture or missing state/command observation is a gap, not a pass. Any divergence,
duplicate batch or live replay command fails acceptance and blocks normal merge
of the completed extension.
