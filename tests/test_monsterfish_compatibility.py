from test_gameplay import setup
from test_quicksave import native_setup


def test_scenario_editor_only_grants_view_actions(lua):
    lua.execute('''
      package.loaded.ffi={}
      local scene=require('code/native/scene').new({composing=false},function() return 0 end)
      local s={screen=12,tab=1,subtab=0,delay=-1,newPlayer=0,mode=1,
        modal=-1,modal2=-1,modal3=-1,activeModalID=-1,activeModalMenu=0,
        textModal=0,textEditor=0,focused=true,platformGeneration=0,inputGeneration=0,sliding=0}
      function scene:snapshot() return s end
      package.loaded['code/native/gameplay']={resolve=function() error('editor is not gameplay') end}
      local production=Catalog.production()
      for _,screen in ipairs({12,14}) do
        s.screen=screen
        local c=assert(Context.resolve(scene:resolve()))
        assert(c.state=='editor' and c.owner=='editor.map' and not c.authority)
        for id,action in pairs(production.actions) do
          if Context.allows(action,c) then
            assert(id:find('^camera%.pan%.') or id=='view.toggle-zoom'
              or id=='view.toggle-interface' or id=='view.rotate-left' or id=='view.rotate-right',id)
          end
        end
        assert(Context.allows(production.actions['camera.pan.up'],c))
        assert(not Context.allows(production.actions['game.quickload'],c))
        local pans={}
        local camera=require('code/camera').new({set=function(key,value) pans[key]=value end})
        assert(camera:start('camera.pan.up',c) and pans.up)
        s.textModal=25
        assert(not scene:resolve())
        camera:beforeFrame(scene:resolve());assert(not pans.up)
        s.textModal=0
        s.modal=25;assert(not scene:resolve());s.modal=-1
        s.delay=10;assert(not scene:resolve());s.delay=-1
      end
      s.screen=17;assert(not scene:resolve())
    ''')


def test_background_video_preserves_pan_identity_and_other_modal_blocks(lua):
    setup(lua)
    lua.execute('''
      package.loaded.ffi={}
      local scene=require('code/native/scene').new({composing=false},function() return 0 end)
      s.tab=1;s.subtab=0;s.activeModalID=-1;s.activeModalMenu=0
      s.platformGeneration=0;s.inputGeneration=0
      function scene:snapshot() return s end
      package.loaded['code/native/gameplay']={resolve=Gameplay.resolve}
      local flags={}
      local camera=require('code/camera').new({set=function(dir,v) flags[dir]=v end})
      local before=assert(Context.resolve(scene:resolve()))
      assert(camera:start('camera.pan.up',before))
      s.modal2=19
      local during=assert(Context.resolve(scene:resolve()))
      assert(Context.same(before,during))
      camera:beforeFrame(during);assert(flags.up)
      s.modal2=-1;assert(Context.same(before,Context.resolve(scene:resolve())))
      s.modal2=27;assert(not scene:resolve())
      camera:beforeFrame(nil);assert(not flags.up)
      s.modal2=19;s.textModal=27;assert(not scene:resolve())
      s.textModal=0;s.modal=121;assert(not scene:resolve())
    ''')


def test_closed_ally_marker_is_ignored_only_when_other_input_owners_are_absent(lua):
    lua.execute('''
      local A=require('code/addresses')
      local memory={[A.screen]=14,[A.gameMode]=3,[A.primaryModal]=-1,
        [A.secondaryModal]=-1,[A.tertiaryModal]=-1,[A.textModal]=123,[A.textEditor]=0}
      package.loaded.ffi={cast=function(_,address) return {[0]=memory[address] or 0} end}
      local platform={focused=function() return true end}
      local scene=require('code/native/scene').new(platform,function() return 0 end)
      assert(scene:snapshot().textModal==0)
      memory[A.primaryModal]=123;assert(scene:snapshot().textModal==123)
      memory[A.primaryModal]=-1;memory[A.secondaryModal]=27;assert(scene:snapshot().textModal==123)
      memory[A.secondaryModal]=-1;memory[A.textEditor]=1;assert(scene:snapshot().textModal==123)
      memory[A.textEditor]=0;memory[A.textModal]=25;assert(scene:snapshot().textModal==25)
    ''')


def test_relocated_load_requires_proved_prefix(lua):
    lua.execute('''
      local Load=require('code/load_context')
      local A=require('code/addresses')
      local s={screen=14,modal=9,activeModalID=9,activeModalMenu=A.loadMenu,
        loadArray=0x100000,textModal=9,textEditor=0,modal2=-1,modal3=-1,
        textIndex=4,textState=1,loadCount=0,loadRows=16,loadOffset=0,loadSelected=-1,loadIdentity=''}
      assert(not Load.owns(s))
      s.loadPrefix=true;assert(Load.owns(s))
      s.textIndex=2;assert(not Load.owns(s))
    ''')


def test_menu_copy_checks_owner_shape_and_load_callback(lua):
    lua.execute('''
      local original,array={},{}
      local menu={[0]={menuItemArray=array}}
      for i=0,5 do
        original[i]={menuItemType=3, callbackParameter={parameter=i},
          itemWidth=10,itemHeight=5,menuItemActionHandler={simple=20}}
        array[i]={menuItemType=3, callbackParameter={parameter=i},
          itemWidth=10,itemHeight=5,menuPointer=menu,menuItemActionHandler={simple=20}}
      end
      package.loaded.ffi={cast=function(kind) return kind=='Menu *' and menu or original end}
      local match=require('code/native/menu_reader').matchesPrefix
      assert(match(10,20,6,true))
      array[3].menuItemActionHandler.simple=30
      assert(not match(10,20,6,true) and match(10,20,6,false))
      array[3].menuPointer=nil
      assert(not match(10,20,6,false))
      array[3].menuPointer=menu;array[4].menuItemType=0x66
      assert(not match(10,20,6,false))
    ''')


def test_quicksave_accepts_compatible_save_copy_but_not_foreign_confirmation(lua):
    native_setup(lua)
    lua.execute('''
      memory[0xb96290]=0x100000
      local Reader=require('code/native/menu_reader')
      local calls=0
      Reader.matchesPrefix=function(menu,original,count,matchAction)
        assert(menu==0xb96290 and original==0x6022f8 and count==25 and not matchAction)
        calls=calls+1
        return true
      end
      start();q:beforeFrame()
      assert(calls>0 and buffer=='Custom Hotkeys Quick')
      overwrite();memory[0xb97ad8]=0x200000;q:beforeFrame()
      assert(not q.active and confirmations==0)
    ''')
