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
      function routed(catalog, bindings, registry, canSubmit)
        local adapter={resolve=function() return current end, recover=function() end,
          canRecover=function() return false end,
          cancelLocalHold=function(id) registry.dispatch(id,'release') end,
          dispatch=function(id,context,native,event)
            registry.dispatch(id,'press',context,event,canSubmit)
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
      assert(not pcall(r.register,spec('view.toggle-zoom',{kind='world'})))
      base.label.en='Edited by the caller'
      local defs=r.freeze()
      local catalog=Catalog.production(defs)
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
      local saved
      local router=routed(c,Catalog.defaults(c),r)
      local profiles=assert(Profiles.new(c,{load=function() return nil,'store.missing' end,
        save=function(_,d) saved=d;return true end},router))
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
      assert(editor:apply() and saved)
      current=facts('game.status')
      assert(messages(1,1,0x20a,120*65536+8,0)==42)
      assert(router:handle(event(66,'up',4)))
      assert(router:handle(event(66,'down',4)) and calls==2)
      current.focused=false
      router:barrier()
      router:handle(repeat_event(66,4))
      assert(calls==2)
    """)


def test_profile_migration_config_and_missing_provider_roundtrip(actions):
    actions.execute("""
      local r=Registry.new()
      r.register(spec(id,{kind='world'},{wheel='up',mods=1}))
      local core=Catalog.production()
      local legacy=Profiles.initial(core)
      local config={example={zoom={button='x2',mods=0}}}
      local combined=Catalog.production(r.freeze(),config)
      local migrated=assert(Profiles.validate(combined,legacy))
      assert(migrated.profiles[migrated.active].bindings[id].button=='x2')
      assert(legacy.profiles[legacy.active].bindings[id]==nil)
      local dormant=assert(Profiles.validate(core,migrated))
      local prior=dormant.profiles[dormant.active]
      assert(prior.unavailable[id].button=='x2' and prior.bindings[id]==nil)
      prior.bindings['game.quicksave']={button='x2',mods=0}
      local occupied=assert(Profiles.validate(combined,dormant))
      local after=occupied.profiles[occupied.active]
      assert(after.unavailable[id].button=='x2' and after.bindings[id]==false)
      after.bindings['game.quicksave']=core.presets['game-default'].bindings['game.quicksave']
      after=assert(Profiles.validate(combined,occupied)).profiles[occupied.active]
      assert(after.unavailable==nil and after.bindings[id].button=='x2')
      local optout=Catalog.production(r.freeze(),{example={zoom=false}})
      assert(Profiles.initial(optout).profiles['Game Default'].bindings[id]==false)
      assert(Profiles.validate(optout,migrated).profiles[migrated.active].bindings[id].button=='x2')
    """)


def test_release_focus_failed_actions_and_native_submission(actions):
    actions.execute("""
      local r=Registry.new()
      local hits,releases,sounds,submitted=0,0,0,0
      local accepted=true
      local localAction=spec(id,{kind='world'},key(66,4),function()
        hits=hits+1;return accepted
      end)
      localAction.release=function() releases=releases+1 end
      localAction.sound=function() sounds=sounds+1 end
      r.register(localAction)
      local command=spec('ext.example.command',{kind='world'},key(67,4))
      command.callback=nil
      command.submit=function() submitted=submitted+1;return true end
      r.register(command)
      local c=Catalog.production(r.freeze())
      current=facts('game.status')
      local canSubmit=false
      local router=routed(c,Catalog.defaults(c),r,function() return canSubmit end)
      router:handle(event(66,'down',4))
      current.focused=false
      router:refresh()
      assert(hits==1 and releases==1 and sounds==1)
      router:handle(event(66,'up',4))
      current.focused=true;accepted=false
      router:handle(event(66,'down',4));router:handle(event(66,'up',4))
      assert(hits==2 and releases==1 and sounds==1)
      router:handle(event(67,'down',4));router:handle(event(67,'up',4))
      assert(submitted==0)
      canSubmit=true
      router:handle(event(67,'down',4));router:handle(event(67,'up',4))
      assert(submitted==1)
      current.state='replay'
      router:handle(event(67,'down',4))
      assert(submitted==1)
    """)


def test_click_binding_requires_unique_anchor_and_derives_signed_relative_call(lua):
    lua.execute("""
      local resolve=require('code/address_bindings').resolveClick
      local seen
      local mock={AOBScan=function(pattern) seen=pattern;return 1000 end,
        scanForAOB=function(pattern,start) assert(pattern==seen and start==1001) end,
        readInteger=function(site) return ({[1011]=9000,[1006]=135,[1028]=-32})[site] end}
      local result=resolve(mock)
      assert(result.owner==9000 and result.id==135 and result.play==1000)
      mock.scanForAOB=function() return 2000 end
      assert(not pcall(resolve,mock))
      mock.AOBScan=function() error('no match') end
      assert(not pcall(resolve,mock))
    """)

def test_custom_modal_requires_live_ui_registry_and_foreground_composition(lua):
    lua.execute("""
      local Modal=require('code/modal_context')
      local s={modal=2044,modal2=-1,modal3=-1,activeModalID=2044,activeModalMenu=123,
        textModal=0,textEditor=0,modalX=10,modalY=10,modalWidth=400,modalHeight=400,
        modalAnimation=32,modalClosing=0,modalBorder=0x200,width=800,height=600}
      local registered={[2044]=function() return 123 end}
      assert(Modal.extensionOwns(s,registered))
      s.textEditor=1;assert(not Modal.extensionOwns(s,registered));s.textEditor=0
      s.activeModalMenu=456;assert(not Modal.extensionOwns(s,registered));s.activeModalMenu=123
      s.modalClosing=1;assert(not Modal.extensionOwns(s,registered));s.modalClosing=0
      s.modal2=4;assert(not Modal.extensionOwns(s,registered));s.modal2=-1
      assert(not Modal.extensionOwns(s,{}))
      s.modal=10;s.activeModalID=10
      assert(not Modal.extensionOwns(s,{[10]=function() return 123 end}))
    """)


def test_wheel_preview_provider_and_profiles_keep_assignments(actions):
    actions.execute("""
      local preview=require('code/wheel_preview')
      local core=Catalog.production()
      local old=Profiles.initial(core)
      old.schema=4
      local saved=old.profiles[old.active]
      saved.bindings['view.resolution-zoom-in']=key(66,4)
      saved.bindings['view.resolution-zoom-out']=false
      saved.bindings['game.quicksave']={button='x1',mods=0}
      local r=Registry.new()
      assert(preview.register(r,'view.resolution-zoom-in',function() end))
      assert(preview.register(r,'view.resolution-zoom-out',function() end))
      local migrated=assert(Profiles.validate(Catalog.production(r.freeze()),old))
      local bindings=migrated.profiles[migrated.active].bindings
      assert(bindings['ext.resolution-based-zoom.in'].scan==66)
      assert(bindings['ext.resolution-based-zoom.out']==false)
      assert(bindings['game.quicksave'].button=='x1')
      assert(bindings['view.resolution-zoom-in']==nil)
      local noZoom=assert(Profiles.validate(core,old)).profiles[old.active]
      assert(noZoom.unavailable['ext.resolution-based-zoom.in'].scan==66)
      assert(noZoom.unavailable['ext.resolution-based-zoom.out']==false)
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


def test_preview_assignments_take_precedence_over_new_presets(actions):
    actions.execute("""
      local old=Profiles.initial(Catalog.production())
      old.schema=4
      old.profiles[old.active].bindings['view.resolution-zoom-in']=key(66,4)
      local r=Registry.new()
      require('code/wheel_preview').register(r,'view.resolution-zoom-in',function() end)
      r.register(spec('ext.example.new',{kind='world'},key(66,4)))
      local saved=assert(Profiles.validate(Catalog.production(r.freeze()),old)).profiles[old.active]
      assert(saved.bindings['ext.resolution-based-zoom.in'].scan==66)
      assert(saved.bindings['ext.example.new']==false and saved.unavailable==nil)
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


def test_changed_provider_action_keeps_profile_and_sets_its_chord_aside(actions):
    actions.execute("""
      local r=Registry.new()
      r.register(spec(id,{kind='world'},{wheel='up',mods=1}))
      r.register(spec('ext.example.other',{kind='world'},key(66,4)))
      local before=Catalog.production(r.freeze())
      local doc=Profiles.initial(before)
      local saved=doc.profiles[doc.active].bindings
      saved['game.quicksave']=key(65,0)
      -- The provider's next version makes the same action a hold, which
      -- cannot use the wheel, and moves another action onto the same chord.
      local after=Registry.new()
      local hold=spec(id,{kind='world'},false)
      hold.release=function() end
      after.register(hold)
      after.register(spec('ext.example.other',{kind='world'},key(66,4)))
      after.register(spec('ext.example.third',{kind='world'},false))
      saved['ext.example.third']=key(66,4)
      local loaded=assert(Profiles.validate(Catalog.production(after.freeze()),doc))
      local profile=loaded.profiles[doc.active]
      assert(profile.bindings['game.quicksave'].scan==65)
      assert(profile.bindings[id]==false and profile.unavailable[id].wheel=='up')
      local kept=profile.bindings['ext.example.other'] or profile.bindings['ext.example.third']
      assert(kept and kept.scan==66)
      assert(profile.bindings['ext.example.other']==false or profile.bindings['ext.example.third']==false)
      -- A broken built-in binding still rejects the document as before.
      saved['game.quicksave']={scan=999,extended=false,mods=0}
      assert(not Profiles.validate(Catalog.production(after.freeze()),doc))
    """)
