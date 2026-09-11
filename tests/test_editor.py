def setup(lua):
    lua.execute('''
      local store={load=function() return nil,'store.missing' end,
        save=function() return true end}
      profiles=assert(Profiles.new(catalog,store,router))
      editor=require('code/editor').new(profiles,catalog,router,function(id)
        return ({['camera.left']='Camera left',['unit.move']='Move unit',
          ['market.buy']='Buy goods',['menu.back']='Go back'})[id]
      end,string.lower,2)
    ''')


def test_search_group_and_keyboard_scroll_keep_focus_visible(lua):
    setup(lua)
    lua.execute('''
      editor:navigate(3)
      local view=editor:view()
      assert(view.first==3 and view.rows[2].selected and view.rows[2].id=='menu.back')
      editor:navigate(-100); assert(editor:view().first==1)
      editor:filter('UNIT'); assert(editor:view().total==1)
      editor:filter('','market'); assert(editor:view().rows[1].id=='market.buy')
      editor:filter('missing'); assert(not editor:clear() and not editor:capture())
    ''')


def test_capture_conflict_keeps_existing_binding(lua):
    setup(lua)
    lua.execute('''
      editor:choose(2); current.owner='hotkeys.capture'
      assert(editor:capture()); assert(not editor:navigate(1))
      router:handle(event(30))
      assert(editor.error=='binding.conflict')
      assert(profiles.draft.profiles.Default.bindings['unit.move'].scan==50)
      assert(not editor.capturing and #calls==0)
      editor:cancel(); assert(editor.closed and not profiles.draft)
    ''')


def test_mouse_row_choice_clear_reset_and_apply_use_same_transaction(lua):
    setup(lua)
    lua.execute('''
      assert(editor:createProfile('Keyboard'))
      assert(editor:choose(2)); assert(editor:clear())
      assert(editor:view().rows[2].binding==false)
      assert(editor:resetAction()); assert(editor:apply())
      assert(editor.closed and profiles.committed.active=='Keyboard')
      assert(not editor:clear())
    ''')


def test_focus_loss_cancels_capture_and_unsticks_editor(lua):
    setup(lua)
    lua.execute('''
      current.owner='hotkeys.capture'
      assert(editor:capture())
      current.focused=false
      router:handle(event(50))
      assert(not editor.capturing and not router.capture)
      assert(editor:navigate(1) and #calls==0)
      current.focused=true
      router:handle(event(50,'up'))
      assert(editor:capture())
      router:barrier()
      assert(not editor.capturing and not router.capture)
    ''')
