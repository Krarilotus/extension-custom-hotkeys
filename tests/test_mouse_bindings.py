def test_mouse_binding_identity_and_exclusive_capture(lua):
    lua.execute('''
      local B=require('code/binding');local seen={}
      for name in pairs(B.buttons) do
        for mods=0,7 do
          local b=assert(B.validate({button=name,mods=mods}))
          assert(B.key(b)<0 and not seen[B.key(b)]);seen[B.key(b)]=true
        end
      end
      assert(not B.validate({button='other',mods=0}))
      assert(not B.validate({button='left',mods=0,scan=30}))
      current=facts('hotkeys.capture');local captured
      router:startCapture(function(b) captured=b end)
      assert(router:handle({button='x1',scan=0,extended=false,kind='down',repeated=false,
        mods=2,altgr=false,win=false,composing=false}))
      assert(captured.button=='x1' and captured.mods==2 and #calls==0)
      assert(router:handle({button='x1',scan=0,extended=false,kind='up'}))
    ''')


def test_mouse_hotkey_uses_same_router_once_and_leaves_text_native(lua):
    lua.execute('''
      local b=Catalog.defaults(catalog);b['unit.move']={button='x1',mods=0}
      assert(router:apply(b));local nextCalls={}
      local h=require('code/messages').new(router,function(...)
        nextCalls[#nextCalls+1]={...};return 27 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() return true end)
      assert(h(4,9,0x20b,65536+32,123)==0)
      assert(h(4,9,0x20c,65536,123)==0 and #calls==1 and #nextCalls==0)
      current.text=true
      assert(h(4,9,0x20b,65536+32,123)==27)
      assert(h(4,9,0x20c,65536,123)==27 and #calls==1 and #nextCalls==2)
    ''')


def test_translated_mouse_drag_release_and_focus_loss_do_not_leak(lua):
    lua.execute('''
      local c=Catalog.new({{id='pointer.order',contexts={'game'},states={'live-sp'},
        command=true,default={button='right',mods=0}}})
      local cancelled=0;local forwarded={}
      local r=Router.new(c,Catalog.defaults(c),{
        resolve=function() return current end,dispatch=function() return 'left' end,
        canRecover=function() return false end,recover=function() end,
        cancelLocalHold=function() end,cancelPointerHold=function() cancelled=cancelled+1 end})
      local h=require('code/messages').new(r,function(...)
        forwarded[#forwarded+1]={...};return 23 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() return true end)
      assert(h(4,9,0x204,2,123)==23)
      assert(forwarded[1][3]==0x201 and forwarded[1][4]==1 and forwarded[1][5]==123)
      assert(h(4,9,0x200,2,456)==23 and forwarded[2][4]==1)
      assert(h(4,9,0x205,0,456)==23 and forwarded[3][3]==0x202)
      assert(cancelled==0)
      assert(h(4,9,0x204,2,123)==23)
      h(4,9,0x8,0,0);assert(cancelled==1)
      h(4,9,0x200,2,456);assert(forwarded[#forwarded][4]==0)
      local count=#forwarded
      assert(h(4,9,0x205,0,456)==0 and #forwarded==count)
    ''')


def test_modern_pointer_modes_reuse_selection_order_and_cancel(lua):
    lua.execute('''
      local p=require('code/pointer_actions')
      local s={selectedCount=1,placement=0,patrol=0,unitMode=1,unitModeAux=1}
      local button,deselect=p.resolve('pointer.select',s)
      assert(button=='left' and deselect)
      assert(p.resolve('pointer.order',s)=='left')
      s.placement=51
      button,deselect=p.resolve('pointer.select',s);assert(button=='left' and not deselect)
      assert(p.resolve('pointer.order',s)=='right')
      s.placement=0;s.patrol=1
      button,deselect=p.resolve('pointer.select',s);assert(not deselect)
      s.selectedCount=0;assert(p.resolve('pointer.order',s)=='right')
    ''')


def test_editor_mouse_controls_remain_native_except_during_capture(lua):
    lua.execute('''
      current=facts('hotkeys.editor');local passed,exclusive=0,0
      local h=require('code/messages').new(router,function(...)
        passed=passed+1;return 17 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() return true end,function() exclusive=exclusive+1;return true end)
      assert(h(4,9,0x201,1,123)==17 and h(4,9,0x202,0,123)==17)
      assert(passed==2 and exclusive==0)
      current=facts('hotkeys.capture');local captured
      router:startCapture(function(b) captured=b end)
      assert(h(4,9,0x207,16,123)==0 and h(4,9,0x208,0,123)==0)
      assert(captured.button=='middle' and passed==2 and exclusive==0)
    ''')
