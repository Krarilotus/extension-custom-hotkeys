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


def test_native_chain_distinguishes_quickslot_release_from_pointer_takeover(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='game.quickload',contexts={'game'},states={'live-sp'},
         command=false,default={button='middle',mods=0}},
        {id='pointer.order',contexts={'game'},states={'live-sp'},
         command=true,default={button='right',mods=0}}})
      local r,quickslot,forwarded,observed
      local platform={owns=function(_,hwnd) return hwnd==9 end,
        observe=function() return false end,
        modifiers=function() return {mods=0,altgr=false,win=false,composing=false} end}
      local callback
      package.loaded.ffi={os='Windows',arch='x86',cast=function(_,value)
        if value==123 then
          return function(fn,priority) callback=fn;return priority end
        end
        if value==456 then
          return function(_,_,message) forwarded=message;return 42 end
        end
        return value
      end}
      package.loaded.jit={off=function() end}
      r=Router.new(c,Catalog.defaults(c),{
        resolve=function() if not quickslot then return current end end,
        dispatch=function(id)
          if id=='pointer.order' then return 'left' end
          r:barrier()
          quickslot=true
        end,
        canRecover=function() return false end,recover=function() end,
        cancelLocalHold=function() end,cancelPending=function() quickslot=false end})
      require('code/native/chain').install({RegisterProc=123,CallNextProc=456},r,platform,nil,
        function(message) observed=message;quickslot=false end,function() return true end)
      local function msg(message,flags) return callback(-110000,9,message,flags,0) end
      assert(msg(0x207,16)==0 and quickslot and observed==0x207)
      assert(msg(0x208,0)==0 and quickslot and observed==0x207 and forwarded==nil)
      assert(msg(0x201,1)==42 and not quickslot and observed==0x201)
      assert(msg(0x202,0)==42 and observed==0x202 and forwarded==0x202)
      assert(msg(0x204,2)==42 and observed==0x204 and forwarded==0x201)
      assert(msg(0x205,0)==42 and observed==0x205 and forwarded==0x202)
    ''')


def test_native_chain_keeps_wheel_quicksave_through_its_remaining_notches(lua):
    # W9 native finding: one wheel spin sends several WM_MOUSEWHEEL notches.
    # The first started Quicksave; the next was treated as pointer takeover and
    # cancelled it, leaving the native Save dialog open with a blank name.
    lua.execute('''
      local c=Catalog.new({
        {id='game.quicksave',contexts={'game'},states={'live-sp'},
         command=false,default={wheel='down',mods=0}},
        {id='camera.pan.left',contexts={'game'},states={'live-sp'},
         command=false,default={scan=30,extended=false,mods=0}}})
      local r,quickslot,forwarded,observed
      local opens,cancels=0,0
      local platform={owns=function(_,hwnd) return hwnd==9 end,
        observe=function() return false end,
        modifiers=function() return {mods=0,altgr=false,win=false,composing=false} end}
      local callback
      package.loaded.ffi={os='Windows',arch='x86',cast=function(_,value)
        if value==123 then
          return function(fn,priority) callback=fn;return priority end
        end
        if value==456 then
          return function(_,_,message) forwarded=message;return 42 end
        end
        return value
      end}
      package.loaded.jit={off=function() end}
      r=Router.new(c,Catalog.defaults(c),{
        resolve=function() if not quickslot then return current end end,
        dispatch=function(id)
          assert(id=='game.quicksave')
          r:barrier()
          quickslot=true;opens=opens+1
        end,
        canRecover=function() return false end,recover=function() end,
        cancelLocalHold=function() end,
        cancelPending=function() if quickslot then cancels=cancels+1 end;quickslot=false end})
      require('code/native/chain').install({RegisterProc=123,CallNextProc=456},r,platform,nil,
        function(message)
          observed=message
          if quickslot then cancels=cancels+1 end
          quickslot=false
        end,function() return true end)
      local function wheel(delta,flags)
        observed,forwarded=nil,nil
        return callback(-110000,9,0x20a,(delta%65536)*65536+(flags or 0),0)
      end
      current=facts()
      assert(wheel(-120)==0 and quickslot and opens==1 and observed==0x20a)
      -- The rest of the same spin stays with the workflow: no takeover and
      -- nothing reaches the Save dialog it opened.
      for _=1,3 do
        assert(wheel(-120)==0 and quickslot and opens==1 and cancels==0)
        assert(observed==nil and forwarded==nil)
      end
      -- Another direction or chord is real pointer input and cancels.
      assert(wheel(-120,8)==42 and not quickslot and cancels==1 and observed==0x20a)
      assert(wheel(-120)==0 and quickslot and opens==2)
      assert(wheel(120)==42 and not quickslot and cancels==2 and observed==0x20a)
      -- A fresh key ends the wheel gesture, so a later notch is takeover again.
      assert(wheel(-120)==0 and quickslot and opens==3)
      assert(callback(-110000,9,0x100,65,30*65536)==42 and quickslot)
      assert(callback(-110000,9,0x101,65,30*65536+3221225472)==42 and quickslot)
      assert(wheel(-120)==0 and observed==0x20a and cancels==3 and opens==4 and quickslot)
    ''')
