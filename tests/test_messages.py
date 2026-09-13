def test_message_chain_arguments_returns_and_command_count(lua):
    lua.execute('''
      local Messages=require('code/messages')
      local forwarded={}
      local handler=Messages.new(router,function(...)
        forwarded[#forwarded+1]={...}; return 54321
      end,function() return {mods=0,altgr=false,win=false,composing=false} end,
      function(hwnd) return hwnd==42 end)
      assert(handler(17,99,0x100,77,50*65536)==54321)
      assert(#calls==0 and forwarded[1][1]==17 and forwarded[1][2]==99)
      assert(handler(17,42,0x100,77,50*65536)==0)
      assert(handler(17,42,0x100,77,50*65536+1073741824)==0)
      assert(handler(17,42,0x101,77,50*65536)==0)
      assert(handler(17,42,0x102,109,50*65536)==0)
      assert(#calls==1 and #forwarded==1)
      assert(handler(17,42,0x200,9,12345)==54321)
      local f=forwarded[2]
      assert(f[1]==17 and f[2]==42 and f[3]==0x200 and f[4]==9 and f[5]==12345)
    ''')


def test_text_input_after_consumed_delayed_char_has_new_ownership(lua):
    lua.execute('''
      router:handle(event(50)); router:handle(event(50,'up'))
      assert(router:handle(event(50,'char')))
      current.text=true
      assert(not router:handle(event(50)))
      assert(not router:handle(event(50,'char')))
      assert(not router:handle(event(50,'up')))
      assert(not router:handle(event(50,'char')))
    ''')


def test_ime_focus_and_layout_messages_cancel_holds_and_are_forwarded(lua):
    lua.execute('''
      local Messages=require('code/messages')
      local n=0
      local h=Messages.new(router,function() n=n+1; return -15 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() return true end)
      for _,message in ipairs({0x6,0x7,0x8,0x1c,0x51,0x10d,0x10e,0x10f,0x82}) do
        assert(h(7,42,0x100,77,50*65536)==0)
        assert(h(7,42,message,0,0)==-15)
        assert(h(7,42,0x100,77,50*65536+1073741824)==0)
        h(7,42,0x101,77,50*65536)
      end
      assert(#calls==9 and n==9)
    ''')


def test_callback_failure_drains_consumed_gesture_without_retry(lua):
    lua.execute('''
      local forwards=0
      local h=require('code/messages').new(router,function() forwards=forwards+1; return 9 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() return true end)
      local original=router.handle
      router.handle=function(self,e) original(self,e); error('after native dispatch') end
      assert(h(1,42,0x100,77,50*65536)==0)
      assert(h(1,42,0x100,77,50*65536+1073741824)==0)
      assert(h(1,42,0x101,77,50*65536)==0)
      assert(h(1,42,0x102,109,50*65536)==0)
      assert(#calls==1 and forwards==0)
      assert(h(1,42,0x100,77,50*65536)==9)
      assert(h(1,42,0x102,109,50*65536)==9)
      assert(h(1,42,0x101,77,50*65536)==9)
      assert(#calls==1 and forwards==3)
    ''')


def test_modifier_failure_before_routing_preserves_native_input(lua):
    lua.execute('''
      local h=require('code/messages').new(router,function() return 9 end,
        function() error('key snapshot unavailable') end,function() return true end)
      assert(h(1,42,0x100,77,50*65536)==9)
      assert(h(1,42,0x101,77,50*65536)==9)
      assert(#calls==0)
    ''')


def test_window_identity_failure_still_drains_previous_consumption(lua):
    lua.execute('''
      local fail=false
      local h=require('code/messages').new(router,function() return 9 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,
        function() if fail then error('window unavailable') end return true end)
      assert(h(1,42,0x100,77,50*65536)==0)
      fail=true
      assert(h(1,42,0x101,77,50*65536)==0)
      assert(h(1,42,0x102,109,50*65536)==0)
      assert(h(1,42,0x100,77,50*65536)==9)
      assert(#calls==1)
    ''')
