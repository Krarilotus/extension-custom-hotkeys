def setup(lua):
    lua.execute('''
      -- Model the OS boundary, including its asynchronous WM_MOUSEMOVE delivery.
      -- Production pointer ownership and viewport conversion run unchanged.
      osx,osy=10,20;focused=true;setOK=true;getOK=true
      user={
        GetClientRect=function(_,r) r[0].right=800;r[0].bottom=600;return 1 end,
        ClientToScreen=function(_,p) p[0].x=p[0].x+100;p[0].y=p[0].y+50;return 1 end,
        SetCursorPos=function(x,y) if not setOK then return 0 end;osx,osy=x,y;return 1 end,
        GetCursorPos=function(p) p[0].x,p[0].y=osx,osy;return getOK and 1 or 0 end}
      package.loaded.ffi={cdef=function() end,load=function() return user end,
        new=function() return {[0]={}} end}
      Pointer=require('code/native/pointer')
      pointer=Pointer.new({window=1,focused=function() return focused end},
        {snapshot=function() return {width=800,height=600} end})
      function moveMessage(x,y) return pointer:observe(0x200,x+65536*y) end
    ''')


def test_move_acknowledgement_and_repeated_position(lua):
    setup(lua)
    lua.execute('''
      assert(moveMessage(10,20))
      assert(pointer:move(300,500));assert(osx==400 and osy==550)
      assert(not pointer:settled())
      assert(not moveMessage(10,20));assert(not pointer:settled())
      assert(not moveMessage(300,500));assert(pointer:settled())
      -- Windows need not send a new movement message for an unchanged position.
      assert(pointer:move(300,500));assert(pointer:settled())
      assert(pointer:move(301,500));assert(not pointer:settled())
      assert(pointer:move(301,500));assert(not pointer:settled())
      assert(not moveMessage(301,500));assert(pointer:settled())
    ''')


def test_pointer_takeover_and_failed_os_calls(lua):
    setup(lua)
    lua.execute('''
      assert(pointer:move(300,500));assert(moveMessage(301,500))
      assert(pointer:observe(0x201,0));assert(pointer:settled())
      assert(pointer:move(300,500));setOK=false
      assert(not pointer:move(400,500));assert(pointer:settled())
      setOK=true;getOK=false
      assert(not pointer:move(400,500));assert(pointer:settled())
      getOK=true;focused=false;assert(not pointer:move(400,500))
    ''')
