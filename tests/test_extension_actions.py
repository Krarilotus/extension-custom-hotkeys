import pytest


@pytest.fixture
def actions(lua):
    lua.execute("""
      Registry=require('code/extension_actions')
      Editor=require('code/editor')
      id='ext.example.zoom'
      labels={en='Zoom',de='Zoom',fr='Zoom',ru='Zoom',hu='Zoom',tr='Zoom',ch='Zoom',es='Zoom',fa='Zoom'}
      function spec(id,context,binding,callback)
        return {id=id,context=context,label=labels,category=labels,default=binding,
          callback=callback or function() return true end}
      end
      function routed(catalog, bindings, registry)
        local adapter={resolve=function() return current end, recover=function() end,
          canRecover=function() return false end,
          cancelLocalHold=function(id) registry.dispatch(id,'release') end,
          dispatch=function(id,context,native,event)
            registry.dispatch(id,'press',context,event)
          end}
        return Router.new(catalog,bindings,adapter)
      end
    """)
    return lua


def test_registration_lifecycle_and_all_translations(actions):
    actions.execute("""
      local r=Registry.new()
      local base=spec(id,{kind='world'},false)
      assert(r.register(base))
      assert(not pcall(r.register,base))
      local incomplete=spec('ext.example.missing',{kind='world'})
      incomplete.label={en='Only English'}
      assert(not pcall(r.register,incomplete))
      for _,bad in ipairs({string.char(192,175),string.char(237,160,128),string.char(195)}) do
        local broken=spec('ext.example.broken',{kind='world'})
        broken.label=setmetatable({en=bad},{__index=labels})
        assert(not pcall(r.register,broken))
      end
      for _,field in ipairs({'submit','sound'}) do
        local extra=spec('ext.example.'..field,{kind='world'})
        extra[field]=function() return true end
        assert(not pcall(r.register,extra))
      end
      assert(not pcall(r.register,spec('view.toggle-zoom',{kind='world'})))
      local view='ext.example.view'
      assert(not pcall(r.register,spec(view,{kind='world',view='true'})))
      assert(not pcall(r.register,spec(view,{kind='editor',view=true})))
      assert(r.register(spec(view,{kind='world',view=true})))
      base.label.en='Edited by the caller'
      local defs=r.freeze()
      local catalog=Catalog.production(defs)
      local camera=catalog.actions['view.toggle-zoom']
      local action=catalog.actions[view]
      assert(not action.command)
      for state in pairs(camera.states) do
        assert(action.states[state] == (state~='editor' and true or nil),state)
      end
      assert(not catalog.actions[id].states.spectator)
      local localized=require('code/locale').new('chinese',nil,catalog.extensionLabels)
      assert(localized(id)=='Zoom')
      assert(localized('group.'..catalog.actions[id].group)=='Zoom')
      assert(not pcall(r.register,spec('ext.example.late',{kind='editor'})))
    """)


def test_panel_and_modal_priority_editor_and_conflicts(actions):
    actions.execute("""
      local r=Registry.new()
      local calls={}
      local chord={button='x2',mods=2}
      for _,item in ipairs({
        {'world',{kind='world'}},{'panel',{kind='panel',tab=43}},
        {'editor',{kind='editor'}},{'modal',{kind='modal',id=5}},
        {'other-modal',{kind='modal',id=7}},{'other-panel',{kind='panel',tab=44}},
      }) do
        local name=item[1]
        r.register(spec('ext.example.'..name,item[2],chord,function()
          calls[#calls+1]=name;return true
        end))
      end
      local c=Catalog.production(r.freeze())
      local bindings=c.presets['game-default'].bindings
      local router=routed(c,bindings,r)
      local function input(owner,panel,modal,state)
        current=facts(owner,state)
        current.panel,current.modal,current.modalReady=panel,modal,true
        local e={kind='down',button='x2',mods=2,repeated=false,win=false,altgr=false,composing=false}
        router:handle(e);e.kind='up';router:handle(e)
      end
      input('game.build','43:0','','live-sp')
      input('game.build','44:2','','live-sp')
      input('game.status','0:0','','live-sp')
      input('game.options','43:0','5','live-sp')
      input('game.options','43:0','7','live-sp')
      input('editor.map','43:0','','editor')
      assert(table.concat(calls,',')=='panel,other-panel,world,modal,other-modal,editor')
      local other=Registry.new()
      other.register(spec('ext.example.collision',{kind='panel',tab=43}))
      local defs=r.freeze()
      defs[#defs+1]=other.freeze()[1]
      c=Catalog.production(defs)
      bindings=c.presets['game-default'].bindings
      bindings['ext.example.collision']=chord
      local _,problem=Catalog.validate(c,bindings)
      assert(problem=='binding.conflict')
    """)


def test_native_capture_and_wheel_default_can_be_rebound(actions):
    actions.execute("""
      local r=Registry.new()
      local calls=0
      r.register(spec(id,{kind='world'},{wheel='up',mods=1},function()
        calls=calls+1;return true
      end))
      local c=Catalog.production(r.freeze())
      current=facts('game.status')
      local router=routed(c,Catalog.defaults(c),r)
      local config=memoryConfig()
      local profiles=config:open(c,router)
      local messages=require('code/messages').new(router,function() return 42 end,
        function() return {mods=0,composing=false,win=false,altgr=false} end,function() return true end)
      assert(messages(1,1,0x20a,120*65536+8,0)==0 and calls==1)
      assert(messages(1,1,0x20a,120*65536,0)==42 and calls==1)
      local localized=require('code/locale').new('english',nil,c.extensionLabels)
      local editor=Editor.new(profiles,c,router,localized,string.lower,5)
      editor:filter('zoom',c.actions[id].group)
      assert(editor:capture())
      current=facts('hotkeys.capture')
      assert(router:handle(event(66,'down',4)))
      assert(editor:apply() and config.tree.bindings.example.zoom.scan==66)
      current=facts('game.status')
      assert(messages(1,1,0x20a,120*65536+8,0)==42)
      assert(router:handle(event(66,'up',4)))
      assert(router:handle(event(66,'down',4)) and calls==2)
      current.focused=false
      router:barrier()
      router:handle(repeat_event(66,4))
      assert(calls==2)
    """)


def test_inactive_provider_entries_stay_in_the_dictionary_and_return(actions):
    actions.execute("""
      local r=Registry.new()
      r.register(spec(id,{kind='world'},{wheel='up',mods=1}))
      local with=Catalog.production(r.freeze())
      local without=Catalog.production()
      local config=memoryConfig()
      local router=routed(with,Catalog.defaults(with),r)
      local profiles=config:open(with,router)
      assert(profiles.committed.bindings[id].wheel=='up' and next(config.tree)==nil)
      profiles:begin();assert(profiles:bind(id,{button='x2',mods=0}));assert(profiles:apply())
      -- Without the provider the entry is not routed, and later edits leave it alone.
      profiles=config:open(without,Router.new(without,Catalog.defaults(without),adapter))
      assert(profiles.committed.bindings[id]==nil)
      profiles:begin();assert(profiles:bind('game.quicksave',{button='x2',mods=0}));assert(profiles:apply())
      assert(config.tree.bindings.example.zoom.button=='x2')
      -- Back with the provider: its saved chord is taken now, so it is set aside, not lost.
      profiles=config:open(with,router)
      assert(profiles.committed.bindings[id]==false and profiles.committed.aside[1]==id)
      profiles:begin();assert(profiles:reset('game.quicksave'));assert(profiles:apply())
      profiles=config:open(with,router)
      assert(profiles.committed.bindings[id].button=='x2')
      -- An explicit clear returns the same way.
      profiles:begin();assert(profiles:bind(id,false));assert(profiles:apply())
      config:open(without,Router.new(without,Catalog.defaults(without),adapter))
      assert(config:open(with,router).committed.bindings[id]==false)
    """)


def test_release_focus_and_failed_actions(actions):
    actions.execute("""
      local r=Registry.new()
      local hits,releases=0,0
      local accepted=true
      local localAction=spec(id,{kind='world'},key(66,4),function()
        hits=hits+1;return accepted
      end)
      localAction.release=function() releases=releases+1 end
      r.register(localAction)
      local failing=spec('ext.example.failing',{kind='world'},key(67,4),function() error('broken') end)
      r.register(failing)
      local c=Catalog.production(r.freeze())
      current=facts('game.status')
      local router=routed(c,Catalog.defaults(c),r)
      router:handle(event(66,'down',4))
      current.focused=false
      router:refresh()
      assert(hits==1 and releases==1)
      router:handle(event(66,'up',4))
      current.focused=true;accepted=false
      router:handle(event(66,'down',4));router:handle(event(66,'up',4))
      assert(hits==2 and releases==1)
      local ok,problem=r.dispatch('ext.example.failing','press')
      assert(not ok and problem:find('broken',1,true))
      assert(r.dispatch('ext.example.failing','press')==false)
    """)


def test_fractional_wheel_preserves_direction_and_two_notches(actions):
    actions.execute("""
      local r=Registry.new()
      local hits=0
      r.register(spec(id,{kind='world'},{wheel='up',mods=1},function(_,input)
        assert(not input.position)
        hits=hits+1;return true
      end))
      local catalog=Catalog.production(r.freeze())
      local router=routed(catalog,Catalog.defaults(catalog),r)
      current=facts('game.status')
      local messages=require('code/messages').new(router,function() return 42 end,
        function() return {mods=0,composing=false,win=false,altgr=false} end,function() return true end)
      local function wheel(delta) return messages(1,1,0x20a,(delta%65536)*65536+8,1001) end
      for i=1,3 do assert(wheel(30)==0 and hits==0) end
      assert(wheel(30)==0 and hits==1)
      assert(wheel(240)==0 and hits==3)
      assert(wheel(60)==0 and wheel(-60)==42 and wheel(60)==0 and hits==3)
      current.generation=current.generation+1
      assert(wheel(60)==0 and hits==3)
      assert(wheel(60)==0 and hits==4)
      local bindings=Catalog.defaults(catalog)
      bindings['pointer.primary']={wheel='down',mods=0}
      local _,problem=Catalog.validate(catalog,bindings)
      assert(problem=='binding.unsupported')
    """)


def test_hold_cancelled_during_start_and_without_input(actions):
    actions.execute("""
      local r=Registry.new()
      local router
      local held,cancels=false,0
      local cancelDuringStart=true
      local provider=spec(id,{kind='world'},key(66,4),function()
        if cancelDuringStart then router:barrier() end
        held=true
        return true
      end)
      provider.release=function() held=false;cancels=cancels+1 end
      r.register(provider)
      local catalog=Catalog.production(r.freeze())
      router=routed(catalog,Catalog.defaults(catalog),r)
      current=facts('game.status')
      router:handle(event(66,'down',4))
      assert(not held and cancels==1 and router.localHolds==0)
      router:handle(event(66,'up',4))
      cancelDuringStart=false
      router:handle(event(66,'down',4))
      assert(held and router.localHolds==1)
      current.generation=current.generation+1
      router:refresh() -- the existing input frame path does this for live holds
      assert(not held and cancels==2 and router.localHolds==0)
    """)


def test_generic_native_dialog_binding_requires_stable_composition(actions):
    actions.execute("""
      local r=Registry.new()
      local hits=0
      for _,modal in ipairs({5,9}) do
        r.register(spec('ext.example.dialog-'..modal,{kind='modal',id=modal},key(66,4),
          function() hits=hits+1;return true end))
      end
      local catalog=Catalog.production(r.freeze())
      local router=routed(catalog,Catalog.defaults(catalog),r)
      for _,item in ipairs({{'game.options','5'},{'game.load','9'}}) do
        current=facts(item[1]);current.modal=item[2]
        current.modalReady=false
        assert(not router:handle(event(66,'down',4)))
        router:handle(event(66,'up',4))
        current.modalReady=true
        assert(router:handle(event(66,'down',4)))
        router:handle(event(66,'up',4))
      end
      assert(hits==2)
    """)


def test_barrier_stops_same_context_wheel_burst(actions):
    actions.execute("""
      local r=Registry.new()
      local hits,router=0,nil
      r.register(spec(id,{kind='world'},{wheel='up',mods=1},function(_,input)
        assert(input.delta==120)
        hits=hits+1
        router:barrier()
        return true
      end))
      local catalog=Catalog.production(r.freeze())
      router=routed(catalog,Catalog.defaults(catalog),r)
      current=facts('game.status')
      local messages=require('code/messages').new(router,function() return 42 end,
        function() return {mods=0,composing=false,win=false,altgr=false} end,function() return true end)
      assert(messages(1,1,0x20a,240*65536+8,0)==0)
      assert(hits==1)
    """)


def test_changed_provider_action_sets_its_saved_chord_aside(actions):
    actions.execute("""
      local tree={bindings={example={zoom={wheel='up',mods=1},third=key(66,4)},
        ['custom-hotkeys']={game={quicksave=key(65,0)}}}}
      -- The provider's next version makes the same action a hold, which
      -- cannot use the wheel, and moves another action onto the same chord.
      local after=Registry.new()
      local hold=spec(id,{kind='world'},false)
      hold.release=function() end
      after.register(hold)
      after.register(spec('ext.example.other',{kind='world'},key(66,4)))
      after.register(spec('ext.example.third',{kind='world'},false))
      local changed=Catalog.production(after.freeze())
      local loaded=Bindings.new(changed,Bindings.source(changed,tree,tree),memoryConfig(),
        Router.new(changed,Catalog.defaults(changed),adapter))
      local b=loaded.committed.bindings
      assert(b['game.quicksave'].scan==65 and b[id]==false)
      assert(b['ext.example.third'].scan==66 and b['ext.example.other']==false)
      assert(#loaded.committed.aside==1 and loaded.committed.aside[1]==id)
      assert(loaded.committed.explicit[id].wheel=='up')
    """)


def test_editor_conflict_with_extension_action_still_asks_the_player(actions):
    actions.execute("""
      local r=Registry.new()
      r.register(spec(id,{kind='world'},{wheel='up',mods=1}))
      local catalog=Catalog.production(r.freeze())
      local router=routed(catalog,Catalog.defaults(catalog),r)
      local profiles=memoryConfig():open(catalog,router)
      assert(profiles:begin())
      local ok,problem=profiles:bind('game.quicksave',{wheel='up',mods=1})
      assert(not ok and problem=='binding.conflict')
      assert(profiles.draft.bindings[id].wheel=='up' and profiles.draft.bindings['game.quicksave'].scan==31)
      ok,problem=profiles:bind(id,profiles.draft.bindings['game.quicksave'])
      assert(not ok and problem=='binding.conflict')
    """)
