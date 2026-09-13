def test_closing_exclusive_editor_drains_repeat_release_and_character(lua):
    lua.execute('''
      local Messages=require('code/messages')
      local open=true;local native={};local edits=0
      local router={handle=function() return false end,barrier=function() end}
      local handle=Messages.new(router,function(_,_,msg) native[#native+1]=msg;return 91 end,
        function() return {mods=0,win=false,altgr=false,composing=false} end,
        function() return true end,
        function(event)
          if open then assert(event.value==13);edits=edits+1;open=false;return true end
        end)
      local lp=28*65536+1
      assert(handle(0,1,256,13,lp)==0)
      assert(handle(0,1,256,13,lp+1073741824)==0)
      assert(handle(0,1,257,13,lp+3221225472)==0)
      assert(handle(0,1,258,13,lp)==0)
      assert(#native==0 and edits==1)
      assert(handle(0,1,256,13,lp)==91)
      assert(#native==1)
    ''')
