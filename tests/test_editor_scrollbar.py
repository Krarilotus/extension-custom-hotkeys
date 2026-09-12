from test_editor import setup


def test_scrollbar_uses_bounded_offsets_and_preserves_visible_selection(lua):
    setup(lua)
    lua.execute('''
      local s=require('code/editor_scrollbar')
      local low,high,value=s.update(editor,1,0,true)
      assert(low==0 and high==2 and value==0)
      low,high,value=s.update(editor,2,999,true)
      assert(value==2 and editor.first==3 and editor.selected==3)
      editor:choose(4)
      low,high,value=s.update(editor,5,0,true)
      assert(value==1 and editor.first==2 and editor.selected==3)
      low,high,value=s.update(editor,3,-100,true)
      assert(value==0 and editor.selected==2)
      assert(select(3,s.update(editor,7,0,true))==1)
      assert(not editor:scroll(0.5))
    ''')


def test_scrollbar_cannot_edit_closed_hidden_or_capturing_editor(lua):
    setup(lua)
    lua.execute('''
      local s=require('code/editor_scrollbar')
      for _,operation in ipairs({2,3,5,6}) do
        s.update(editor,operation,2,false)
        assert(editor.first==1)
      end
      editor:capture()
      s.update(editor,6,2,true);assert(editor.first==1 and editor.capturing)
      editor:cancelCapture();editor:filter('missing')
      assert(select(2,s.update(editor,1,0,true))==0)
      s.update(editor,6,2,true);assert(editor.first==1)
      editor:cancel();assert(not editor:scroll(2))
    ''')


def test_filter_then_scroll_recomputes_native_bounds(lua):
    setup(lua)
    lua.execute('''
      local s=require('code/editor_scrollbar')
      s.update(editor,2,2,true)
      editor:filter('unit')
      local low,high,value=s.update(editor,4,2,true)
      assert(low==0 and high==0 and value==0)
      assert(editor:view().rows[1].id=='unit.move')
    ''')


def test_native_editor_hidden_controls_and_keyboard_selection(lua):
    setup(lua)
    lua.execute('''
      package.loaded['ffi']={}
      package.loaded['code/native/text']={}
      package.loaded['code/native/encoding']={}
      local View=require('code/native/editor_view')
      local Geometry=require('code/editor_layout')
      local v=setmetatable({controller=editor,page='bindings',focus=4,
        controls=Geometry.controls('bindings'),owns=function() return true end},View)
      assert(not v:visible(116) and not v:visible(115) and not v:visible(16))
      assert(not v:activate(116) and not v:activate(16))
      assert(v:input({kind='down',value=40,mods=0}))
      assert(editor.selected==2 and v.focus==5)
      assert(v:input({kind='down',value=13,mods=0}))
      assert(editor.capturing)
      editor:cancelCapture()
      v.page='profiles';v.controls=Geometry.controls('profiles');v.focus=1
      assert(not v:activate(107) and not v:activate(1))
      assert(v:input({kind='down',value=40,mods=0}))
      assert(editor.selected==2 and not editor.capturing)
    ''')


def test_page_switch_uses_menu_value_and_preserves_modal_position(lua):
    setup(lua)
    lua.execute('''
      package.loaded['ffi']={}
      package.loaded['code/native/text']={}
      package.loaded['code/native/encoding']={}
      local View=require('code/native/editor_view')
      local Geometry=require('code/editor_layout')
      local menu={xPosition=260,yPosition=80}
      local ptr=setmetatable({[0]=menu},{__index=function() error('array has no named member') end})
      local rebuilds=0
      game={Input={mouseState={}},UI={Menu=function(p,items)
        assert(p==ptr and items);rebuilds=rebuilds+1
        p[0].xPosition=0;p[0].yPosition=0
      end}}
      local v=setmetatable({router=router,tables={bindings={},profiles={}},
        pages={bindings=Geometry.controls('bindings'),profiles=Geometry.controls('profiles')},
        menu={pMenu=ptr,menu=menu},resetMouse=function() end},View)
      v:setPage('profiles')
      assert(menu.xPosition==260 and menu.yPosition==80 and rebuilds==1)
      assert(v.page=='profiles' and v.controls[1].id==118 and v.focus==1)
      assert(v.menu.menuItems==v.tables.profiles)
    ''')
