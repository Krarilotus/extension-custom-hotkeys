def test_wheel_chord_precision_passthrough_and_cancellation(lua):
    lua.execute('''
      local B=require('code/binding')
      local c=Catalog.new({{id='view.zoom',contexts={'game'},states={'live-sp'},
        command=false,default={wheel='up',mods=1}}})
      local count,available=0,true
      local r=Router.new(c,Catalog.defaults(c),{
        resolve=function() return current end,
        available=function() return available end,
        dispatch=function() count=count+1 end,
        canRecover=function() return false end,recover=function() end,cancelLocalHold=function() end})
      local h=require('code/messages').new(r,function(...) return 87 end,
        function() return {mods=0,altgr=false,win=false,composing=false} end,function(hwnd) return hwnd==9 end)
      assert(h(19,9,0x20a,120*65536,123)==87 and count==0) -- plain wheel
      assert(h(19,9,0x20a,60*65536+8,123)==0 and count==0)
      assert(h(19,9,0x20a,60*65536+8,123)==0 and count==1)
      assert(h(19,9,0x20a,240*65536+8,123)==0 and count==3)
      assert(h(19,9,0x20a,(65536-120)*65536+8,123)==87) -- unbound down
      assert(h(19,9,0x20e,120*65536+8,123)==87) -- horizontal wheel
      assert(h(19,99,0x20a,120*65536+8,123)==87)
      available=false;assert(h(19,9,0x20a,120*65536+8,123)==87 and count==3)
      available=true;h(19,9,0x20a,60*65536+8,123);r:barrier()
      h(19,9,0x20a,60*65536+8,123);assert(count==3)
      current.text=true;assert(h(19,9,0x20a,120*65536+8,123)==87 and count==3)
      for _,wheel in ipairs({'up','down'}) do
        for mods=0,7 do
          local b=assert(B.validate({wheel=wheel,mods=mods}))
          assert(B.key(b)~=B.key({button='left',mods=mods}))
        end
      end
      assert(not B.validate({wheel='up',button='left',mods=0}))
      local production=Catalog.production()
      local bindings=Catalog.defaults(production)
      bindings['pointer.select']={wheel='up',mods=7}
      local valid,reason=Catalog.validate(production,bindings)
      assert(not valid and reason=='binding.unsupported') -- a notch cannot hold/release a pointer
    ''')


def test_wheel_capture_and_callback_failure_do_not_leak(lua):
    lua.execute('''
      current=facts('hotkeys.capture');local captured
      router:startCapture(function(b) captured=b end)
      assert(router:wheel({delta=-30,mods=1,win=false,altgr=false,composing=false}))
      assert(captured.wheel=='down' and captured.mods==1 and #calls==0)
      current=facts('game')
      local c=Catalog.new({{id='view.zoom',contexts={'game'},states={'live-sp'},
        command=false,default={wheel='down',mods=1}}})
      local count=0
      local r=Router.new(c,Catalog.defaults(c),{
        resolve=function() return current end,dispatch=function() count=count+1;error('after action') end,
        canRecover=function() return false end,recover=function() end,cancelLocalHold=function() end})
      assert(r:wheel({delta=-240,mods=1,win=false,altgr=false,composing=false}))
      assert(count==1 and r.blocked)
      assert(not r:wheel({delta=-120,mods=1,win=false,altgr=false,composing=false}))
    ''')


def test_optional_zoom_profiles_preserve_custom_choices(lua):
    lua.execute('''
      local c=Catalog.production();local P=require('code/profiles')
      local old=P.initial(c);old.schema=3
      for _,p in pairs(old.profiles) do
        p.bindings['view.resolution-zoom-in']=nil;p.bindings['view.resolution-zoom-out']=nil
      end
      local migrated=assert(P.validate(c,old))
      assert(migrated.schema==4)
      assert(migrated.profiles['Game Default'].bindings['view.resolution-zoom-in'].wheel=='up')
      local p=migrated.profiles['Game Default']
      p.bindings['view.resolution-zoom-in']=false
      assert(P.validate(c,migrated).profiles['Game Default'].bindings['view.resolution-zoom-in']==false)
    ''')
