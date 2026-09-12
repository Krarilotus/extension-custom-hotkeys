# 0.1.8: corrected signature, existing UCP integration

Custom Hotkeys uses the existing UCP 3.0.7 `core.AOBScan`, AOB cache and
`utils.AOBExtract`. No replacement RPS DLL, framework archive or new API is
required. The proposed shared uniqueness dependency has been removed.

An overlapping `playerLord` pattern missed by the old offline verifier now
includes enough short-branch context to distinguish the intended player field.
Relocatable operands remain wildcarded. Offline validation counts overlapping
matches across six local/official EFIGS and Polish Crusader/Extreme fixtures.
Stock runtime first-match semantics remain unchanged; the fixture audit is
not a runtime uniqueness guarantee for unknown executables.

All existing profiles, controls, eleven game languages, native action paths,
Recorder and Automarket integration are preserved. Multiplayer and Recorder
remain open for testing. No feature activation locks were added.

Validation receipts and the public download are maintained in the
[Store preview](https://github.com/UnofficialCrusaderPatch/UCP3-extensions-store/tree/release/custom-hotkeys-3.0.7/previews/custom-hotkeys).
The earlier custom-framework smoke at commit `89cc712` is historical evidence
only, not validation of this stock-framework package.

Full gameplay/text/focus, two-peer multiplayer, replay/state restore, high-speed
simulation and normal reviewed merge remain outstanding. Two-PC testing is
reserved for manual acceptance; it does not block this development preview.
