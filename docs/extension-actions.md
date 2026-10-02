# Optional view actions and wheel bindings

Custom Hotkeys owns input routing, modifier chords, profile persistence, conflict
checks and binding capture. Resolution Based Zoom owns the resolution ladder and
the native display-mode action. It registers callbacks during `enable()`, before
the framework's `afterInit` callbacks start the Hotkeys runtime:

```lua
modules['custom-hotkeys']:registerActionHandler('view.resolution-zoom-in', zoomIn)
modules['custom-hotkeys']:registerActionHandler('view.resolution-zoom-out', zoomOut)
```

The two known actions are local view actions, not simulation commands. Registration
rejects unknown IDs, duplicate handlers and late registration. It adds no private
input dispatcher or native hook. Providers must resolve their own unavoidable
native actions through their existing owner APIs or supported framework discovery.

Fresh profiles use Ctrl+wheel up/down. Old named presets acquire these controls
only where they do not conflict; custom profiles keep them unbound and explicit
OFF bindings remain OFF. The profile schema is 4. The catalog remains stable when
Zoom is absent, so removing Zoom does not invalidate saved Hotkeys profiles.
Unavailable actions pass input to the existing Windows chain.

WM_MOUSEWHEEL uses the message's Ctrl/Shift flags and the input owner's focus,
Alt/IME state and context. Ordinary wheel input retains all native arguments and
the actual `CallNextProc` return value. Only an eligible, bound chord is consumed,
including its partial high-resolution turns. Partial turns are discarded on a
focus/context/binding change or an unowned gesture. Horizontal wheel is unchanged.
Wheel bindings are impulses and cannot be assigned to hold actions or native
pointer buttons, which require paired press/release messages.

Reuse evidence: `code/messages.lua`, `code/router.lua`, `code/binding.lua`,
`code/profiles.lua`, `code/native/chain.lua` and their component tests at parent
`844d54d` already own the relevant paths. The missing capabilities were wheel
impulses and an optional callback for these catalog actions. `winProcHandler`
1.0.0's actual collision-resolved priority and `CallNextProc` ABI remain in use.
No other worker's branch is changed.

Component checks do not prove native acceptance. Test in normal Crusader and
Extreme: Ctrl+wheel changes zoom only; ordinary wheel keeps its action; menus,
text entry, background focus and provider absence pass through; rebind and save
both actions; hold Ctrl and scroll with troops selected without changing stance;
test graphics scaling, loaded games and Recorder composition. Multiplayer testing
belongs to players.
