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


def test_explicit_conflict_swap_is_draft_only_and_invalidated_by_other_edits(lua):
    setup(lua)
    lua.execute('''
      editor:choose(2);current.owner='hotkeys.capture'
      assert(editor:capture());router:handle(event(30))
      assert(editor.reassignment.other=='camera.left')
      assert(editor:reassign())
      local draft=profiles.draft.profiles.Default.bindings
      assert(draft['unit.move'].scan==30 and draft['camera.left'].scan==50)
      assert(profiles.committed.profiles.Default.bindings['unit.move'].scan==50)
      assert(#calls==0 and not editor.reassignment)
      editor:cancel()
    ''')
    setup(lua)
    lua.execute('''
      editor:choose(2);current.owner='hotkeys.capture'
      assert(editor:capture());router:handle(event(30,'up'));router:handle(event(30))
      assert(editor.reassignment)
      assert(editor:clear());assert(not editor:reassign())
      assert(profiles.draft.profiles.Default.bindings['camera.left'].scan==30)
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


def test_replaced_native_modal_discards_draft_without_touching_replacement(lua):
    setup(lua)
    lua.execute('''
      local ownership=require('code/editor_ownership')
      local view={opened=true,parentScreen=41,modalID=2041,controller=editor,
        router=router,text={}}
      assert(editor:createProfile('Unapplied'))
      assert(ownership.reconcile(view,{screen=41,modal=2041,focused=false}))
      assert(profiles.draft and view.text)
      current.owner='hotkeys.capture'; assert(editor:capture())
      local replacement={screen=42,modal=12}
      assert(not ownership.reconcile(view,replacement))
      assert(replacement.screen==42 and replacement.modal==12)
      assert(not view.opened and not view.text and not router.capture)
      assert(editor.closed and not profiles.draft)
      assert(not profiles.committed.profiles.Unapplied and #calls==0)
    ''')
