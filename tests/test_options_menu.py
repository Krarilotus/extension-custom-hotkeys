def test_options_roots_keep_native_order_and_leave_recorder_pause_alone(lua):
    lua.execute('''
      local menus={}
      local function row(parameter,y)
        return {menuItemType=0x02000003,callbackParameter={parameter=parameter},
          position={position={x=100,y=y}},itemWidth=300,itemHeight=27}
      end
      local group={menuItemType=0x01000000}
      local pause={[0]=group,[1]=row(25,100),[2]=row(4,135),[3]=row(5,170),[4]=row(17,215)}
      local main={[0]=group,[1]=row(25,130),[2]=row(4,162),[3]=row(5,194),
        [4]=row(45,226),[5]=row(17,268),[6]=group,[7]=row(2,88),[8]=row(9,300)}
      menus[12]={pMenu={id=12},menuItems=pause,menuItemsCount=5}
      menus[44]={pMenu={id=44},menuItems=main,menuItemsCount=9}
      package.loaded.ffi={new=function(_,size)
        local array={};for i=0,size-1 do array[i]={} end;return array end,
        cast=function(_,callback) return callback end}
      local drawings={}
      package.loaded['code/native/editor_skin']={button=function() drawings[#drawings+1]='button' end,
        caption=function() drawings[#drawings+1]='caption' end,text=1,selectedText=2}
      api={ui={Menu={fromPointer=function(_,pointer,id)
        assert(pointer==id and (id==12 or id==44));return menus[id] end}}}
      remote={interface={modalMenuAddress=function(id)
        assert(id==12 or id==44);return id end}}
      game={Rendering={ButtonState={}},UI={Menu=function(pointer,items) pointer.items=items end}}
      local current={modal=12,activeModalID=12,activeModalMenu=12}
      local scene={snapshot=function() return current end}
      local opened=0
      local view={open=function() opened=opened+1 end,labels=function() return 'Custom Hotkeys' end,
        layout=function() return {text='Custom Hotkeys'} end}
      local pins=require('code/native/options_menu').install(scene,view)
      assert(#pins==2 and menus[5]==nil)
      local p=menus[12].pMenu.items
      assert(p[4].menuItemType==0x01000000 and p[5].position.position.y==205)
      assert(p[6].menuItemType==0x01000000 and p[7].callbackParameter.parameter==17)
      assert(p[7].position.position.y==250 and p[8].menuItemType==0x66)
      p[4].menuItemActionHandler.simple(1);assert(opened==1)
      p[4].menuItemRenderFunction.simple(1);assert(#drawings==2)
      current.modal=5;p[4].menuItemRenderFunction.simple(1);assert(#drawings==2)
      local m=menus[44].pMenu.items
      assert(m[5].menuItemType==0x01000000 and m[6].position.position.y==248)
      assert(m[8].callbackParameter.parameter==17 and m[8].position.position.y==280)
      assert(m[10].callbackParameter.parameter==2 and m[10].position.position.y==88)
      assert(m[11].callbackParameter.parameter==9 and m[11].position.position.y==312)
      assert(m[12].menuItemType==0x66)
    ''')


def test_editor_returns_to_owning_options_modal(lua):
    from test_editor_hover import prepare
    prepare(lua)
    lua.execute('''
      local calls={}
      snapshot.modal=12
      view.scene.resolve=function() view.scene.current=snapshot;return {owner='game.options'} end
      game.UI.activateModalMenu=function(_,id,retain)
        calls[#calls+1]={id,retain}
        snapshot.modal=id
      end
      assert(view:open() and view.parentModal==12)
      assert(calls[1][1]==2041 and calls[1][2]==false)
      assert(view:close(false))
      assert(calls[2][1]==12 and calls[2][2]==false)
      snapshot.modal=5
      assert(not view:open())
    ''')
