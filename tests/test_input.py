import pytest


@pytest.mark.parametrize('scan,mods,extended', [
    (0, 0, False), (128, 0, False), (1.5, 0, False), (30, 8, False),
    (29, 0, False), (56, 0, True), (91, 0, True), (69, 0, False),
    (15, 4, False), (62, 4, False), (83, 5, True), (88, 3, False),
])
def test_invalid_and_reserved(lua, scan, mods, extended):
    lua.globals().candidate = lua.table_from(dict(scan=scan, mods=mods, extended=extended))
    lua.execute('assert(not Binding.validate(candidate))')


def test_physical_keys_and_numpad_are_distinct(lua):
    lua.execute('''
      assert(not Binding.same(key(28), key(28,0,true)))
      assert(not Binding.same(key(30), key(30,1)))
      assert(Binding.validate(key(28,0,true)))
    ''')


@pytest.mark.parametrize('field,value', [
    ('verified','false'), ('focused','false'), ('text','true'), ('composing','true'),
    ('transition','true'), ('state',"'unknown'"), ('owner',"'covered-market'"),
    ('generation','nil'), ('screen','nil'), ('panel','nil'), ('modal','nil'),
    ('focus','nil'), ('selection','nil'), ('targeting','nil'), ('authority','nil'),
])
def test_unknown_inactive_or_text_context_never_dispatches(lua, field, value):
    lua.execute(f'''
      current.{field}={value}
      assert(not router:handle(event(50)))
      assert(not router:handle(event(50,'char')))
      assert(not router:handle(event(50,'up')))
      assert(#calls==0)
    ''')


@pytest.mark.parametrize('state', ['replay','menu'])
def test_no_live_commands_during_replay_or_frontend(lua, state):
    lua.globals().state_name = state
    lua.execute("current.state=state_name; router:handle(event(50)); assert(#calls==0)")


def test_authority_and_hidden_menu(lua):
    lua.execute('''
      router:handle(event(48)); router:handle(event(48,'up')); assert(#calls==0)
      current.owner='market'; current.authority=false
      router:handle(event(48)); router:handle(event(48,'up')); assert(#calls==0)
      current.authority=true
      assert(router:handle(event(48))); assert(calls[1]=='market.buy')
    ''')


def test_repeat_release_character_pairing_and_no_duplicate(lua):
    lua.execute('''
      assert(router:handle(event(50)))
      for i=1,1000 do
        assert(router:handle(event(50)))
        assert(router:handle(event(50,'char')))
      end
      assert(#calls==1)
      assert(router:handle(event(50,'up')))
      assert(not router:handle(event(50,'up')))
      assert(router:handle(event(50))); assert(#calls==2)
    ''')


def test_forwarded_text_hold_is_quarantined_after_focus_transition(lua):
    lua.execute('''
      current.text=true
      assert(not router:handle(event(50)))
      assert(not router:handle(event(50,'char')))
      current.text=false; current.generation=2
      assert(router:handle(repeat_event(50)))
      assert(router:handle(event(50,'char')))
      assert(not router:handle(event(50,'up')))
      assert(#calls==0)
      assert(router:handle(event(50))); assert(#calls==1)
    ''')


@pytest.mark.parametrize('transition', [
    "current.text=true", "current.focused=false", "current.generation=2",
    "current.modal='load'", "current.panel='market'", "current.selection='none'",
    "current.state='replay'", "current.targeting='building'",
])
def test_held_keys_never_cross_state_boundaries(lua, transition):
    lua.execute(f'''
      assert(router:handle(event(50))); assert(#calls==1)
      {transition}
      router:handle(repeat_event(50)); router:handle(event(50,'char'))
      assert(router:handle(event(50,'up'))); assert(#calls==1)
    ''')


def test_dispatch_rechecks_actual_state(lua):
    lua.execute('''
      local reads=0
      adapter.resolve=function()
        reads=reads+1
        if reads==2 then current.text=true end
        return current
      end
      assert(not router:handle(event(50))); assert(#calls==0)
    ''')


def test_profile_change_quarantines_held_key(lua):
    lua.execute('''
      router:handle(event(50)); assert(#calls==1)
      local bindings=Catalog.defaults(catalog)
      bindings['unit.move']=key(30); bindings['camera.left']=key(50)
      assert(router:apply(bindings))
      router:handle(repeat_event(50)); assert(#calls==1)
      router:handle(event(50,'up')); router:handle(event(50))
      assert(#calls==2 and calls[2]=='camera.left')
    ''')


def test_capture_cannot_activate_following_dialog(lua):
    lua.execute('''
      current.owner='hotkeys.capture'
      local captured
      router:startCapture(function(value) captured=value; current=facts() end)
      assert(router:handle(event(50)))
      assert(captured.scan==50 and #calls==0)
      assert(router:handle(repeat_event(50))); assert(router:handle(event(50,'up')))
      assert(#calls==0)
      router:handle(event(50)); assert(#calls==1)
    ''')


def test_capture_cancel_invalid_key_and_recovery(lua):
    lua.execute('''
      current.owner='hotkeys.capture'
      local reason
      router:startCapture(function(_,err) reason=err end)
      router:handle(event(15,'down',4)); assert(reason=='binding.reserved')
      router:handle(event(15,'up',4)); router:handle(event(1))
      assert(reason=='capture.cancel' and not router.capture)
      current=facts(); router:handle(event(88,'down',3)); assert(recovered==1)
      router:handle(event(88,'up',3)); current.text=true
      router:handle(event(88,'down',3)); assert(recovered==1)
    ''')


@pytest.mark.parametrize('scan,mods', [(15,4),(62,4),(1,1),(1,4),(57,4),(83,5)])
def test_system_gestures_remain_forwarded_during_capture_and_handoff(lua,scan,mods):
    lua.execute(f'''
      current.owner='hotkeys.capture'
      local reason
      router:startCapture(function(_,err) reason=err end)
      assert(not router:handle(event({scan},'down',{mods})))
      assert(reason=='binding.reserved' and router.capture and #calls==0)
      router:barrier()
      assert(not router:handle(repeat_event({scan}, {mods})))
      assert(not router:handle(event({scan},'up',{mods})))
      assert(#calls==0)
    ''')


@pytest.mark.parametrize('field', ['altgr', 'win', 'composing', 'repeated'])
def test_platform_composition_and_preexisting_holds(lua, field):
    lua.execute(f"local e=event(50); e.{field}=true; router:handle(e); assert(#calls==0)")


def test_reentrant_or_throwing_native_adapter_cannot_repeat(lua):
    lua.execute('''
      adapter.dispatch=function(id)
        calls[#calls+1]=id
        assert(router:handle(event(30)))
        error('native outcome uncertain')
      end
      assert(router:handle(event(50))); assert(#calls==1)
      router:handle(event(50,'up')); router:handle(event(50)); assert(#calls==1)
      assert(router.blocked)
    ''')


@pytest.mark.parametrize('transition', [
    "router:handle(event(30,'up'))", "router:barrier()",
    "current.text=true; router:handle(event(20))",
    "current.generation=2; router:handle(event(20))",
    "current.focused=false; router:handle(event(20))",
])
def test_local_hold_is_released_once_on_end_or_transition(lua, transition):
    lua.execute('''
      local c=Catalog.new({{id='camera.left',contexts={'game'},states={'live-sp'},
        command=false,behavior='hold-local',default=key(30)}})
      local cancelled=0
      adapter.cancelLocalHold=function(id)
        assert(id=='camera.left'); cancelled=cancelled+1
      end
      router=Router.new(c,Catalog.defaults(c),adapter)
      router:handle(event(30)); assert(#calls==1)
    ''' + transition + '''
      router:barrier(); router:handle(event(30,'up'))
      assert(cancelled==1 and #calls==1)
    ''')


def test_disjoint_binding_and_ambiguous_conflict(lua):
    lua.execute('''
      local b=Catalog.defaults(catalog)
      b['market.buy']=key(50)
      assert(Catalog.validate(catalog,b))
      b['camera.left']=key(50)
      local ok,err=Catalog.validate(catalog,b)
      assert(not ok and err=='binding.conflict')
    ''')


def test_displaced_native_requires_replacement_and_old_key_is_suppressed(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='armory.open',contexts={'game'},states={'live-sp'},command=false,default=key(30)},
        {id='camera.left',contexts={'game'},states={'live-sp'},command=false,default=key(75,0,true)}
      },{{action='armory.open',binding=key(30)}})
      local b=Catalog.defaults(c); b['camera.left']=key(30)
      assert(not Catalog.validate(c,b))
      b['armory.open']=false; assert(not Catalog.validate(c,b))
      b['armory.open']='bad'; assert(not Catalog.validate(c,b))
      b['armory.open']=key(30,2); assert(Catalog.validate(c,b))
      b['camera.left']=key(75,0,true)
      local r=Router.new(c,b,adapter)
      assert(r:handle(event(30))); assert(#calls==0)
      assert(r:handle(event(30,'up')))
      current.text=true
      assert(not r:handle(event(30))); assert(not r:handle(event(30,'char')))
    ''')
