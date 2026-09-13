def setup(lua):
    lua.execute('''
      catalog=Catalog.production()
      current=facts('game.build');current.screen='14';current.panel='20:0'
      router=Router.new(catalog,Catalog.defaults(catalog),adapter)
      saved=nil
      store={load=function() return saved,'store.missing' end,
        save=function(_,document) saved=document;return true end}
      profiles=assert(Profiles.new(catalog,store,router))
    ''')


def test_editor_capture_shares_key_across_construction_tabs_and_persists(lua):
    setup(lua)
    lua.execute('''
      local editor=require('code/editor').new(profiles,catalog,router,function(id) return id end,string.lower,18)
      for _,id in ipairs({'build.select.woodsman','build.select.wheatfarm','unit.control.catapult'}) do
        for i,row in ipairs(editor.rows) do if row.id==id then editor.selected=i end end
        current.owner='hotkeys.capture'
        assert(editor:capture());assert(router:handle(event(87)))
        router:handle(event(87,'up'))
        assert(not editor.capturing and not editor.error and not editor.reassignment)
      end
      assert(editor:apply())
      profiles=assert(Profiles.new(catalog,store,router))
      for _,id in ipairs({'build.select.woodsman','build.select.wheatfarm','unit.control.catapult'}) do
        assert(router.bindings[id].scan==87)
      end
      current.owner='game.build'
      for _,pair in ipairs({{'20:0','build.select.woodsman'}, {'40:0','build.select.wheatfarm'},
          {'61:0','unit.control.catapult'}}) do
        current.panel=pair[1];local before=#calls
        assert(router:handle(event(87)));router:handle(event(87,'up'))
        assert(#calls==before+1 and calls[#calls]==pair[2])
      end
      current.panel='28:0';local before=#calls
      assert(not router:handle(event(87)));router:handle(event(87,'up'))
      assert(#calls==before)
    ''')


def test_same_panel_and_global_shortcuts_still_conflict_without_losing_bindings(lua):
    setup(lua)
    lua.execute('''
      profiles:begin();assert(profiles:bind('build.select.woodsman',key(87)))
      for _,id in ipairs({'build.select.quarry','camera.focus.lord'}) do
        local ok,err=profiles:bind(id,key(87));assert(not ok and err=='binding.conflict')
      end
      assert(profiles:bind('build.select.granary',key(86)))
      local ok,err=profiles:bind('build.select.mill',key(86))
      assert(not ok and err=='binding.conflict') -- granary belongs to tabs25 AND49
      assert(profiles:bind('build.select.woodsman',key(16))) -- Q stance is units-only
      assert(profiles:apply())
      assert(router.bindings['unit.stance.stand-ground'].scan==16)
      current.panel='20:0';router:handle(event(16));router:handle(event(16,'up'))
      assert(calls[#calls]=='build.select.woodsman')
      current.panel='61:0';router:handle(event(16));router:handle(event(16,'up'))
      assert(calls[#calls]=='unit.stance.stand-ground')
    ''')


def test_shared_key_transition_repeat_text_and_replay_never_leak_commands(lua):
    setup(lua)
    lua.execute('''
      local bindings=Catalog.defaults(catalog)
      bindings['build.select.woodsman']=key(87);bindings['build.select.wheatfarm']=key(87)
      assert(router:apply(bindings))
      assert(router:handle(event(87)));assert(#calls==1)
      current.panel='40:0';router:handle(repeat_event(87));assert(#calls==1)
      router:handle(event(87,'up'));assert(router:handle(event(87)));assert(#calls==2)
      router:handle(event(87,'up'))
      for _,field in ipairs({'text','composing','transition'}) do
        current[field]=true;assert(not router:handle(event(87)))
        router:handle(event(87,'up'));current[field]=false
      end
      current.focused=false;assert(not router:handle(event(87)));router:handle(event(87,'up'))
      current.focused=true;current.owner='game.options'
      assert(not router:handle(event(87)));router:handle(event(87,'up'))
      current.owner='game.build';current.state='replay'
      assert(not router:handle(event(87)));assert(#calls==2)
    ''')
