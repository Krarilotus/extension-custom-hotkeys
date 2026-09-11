from test_gameplay import setup


def test_quicksave_native_workflow_commits_each_step_once_and_stops_at_handoff(lua):
    lua.execute("""
      local phase,pending='name',false
      local calls={open=0,name=0,confirm=0,cancel=0}
      local q=require('code/quickslot').new({
        open=function() calls.open=calls.open+1;return {} end,
        observe=function() return phase end,
        submitName=function() calls.name=calls.name+1;return true end,
        confirm=function() calls.confirm=calls.confirm+1;pending=true;return true end,
        pending=function() return pending end,cancel=function() calls.cancel=calls.cancel+1 end})
      assert(q:start({}) and not q:start({}))
      for i=1,5 do q:beforeFrame() end
      assert(calls.name==1 and calls.confirm==0)
      phase='confirm';for i=1,5 do q:beforeFrame() end
      assert(calls.confirm==1)
      phase='progress';q:beforeFrame();assert(not q.active and calls.cancel==1)
      q:beforeFrame();q:cancel();assert(calls.cancel==1 and calls.open==1)
      phase='name';assert(q:start({}));q:beforeFrame()
      phase='done';q:beforeFrame();assert(not q.active and calls.name==2 and calls.confirm==1)
    """)


def test_quicksave_never_retries_rejected_uncertain_or_cancelled_steps(lua):
    lua.execute("""
      local phase,accept='name',false
      local attempts,cancels=0,0
      local q=require('code/quickslot').new({open=function() return {} end,
        observe=function() return phase end,
        submitName=function() attempts=attempts+1;return accept end,
        confirm=function() attempts=attempts+1;return false end,
        pending=function() return false end,cancel=function() cancels=cancels+1 end})
      assert(q:start({}));q:beforeFrame();q:beforeFrame()
      assert(not q.active and attempts==1)
      accept=true;assert(q:start({}));q:beforeFrame();phase='confirm';q:beforeFrame()
      assert(not q.active and attempts==3)
      phase='name';assert(q:start({}));q:beforeFrame();phase=nil;q:beforeFrame()
      assert(not q.active and attempts==4)
      phase='name';assert(q:start({}));for i=1,92 do q:beforeFrame() end
      assert(not q.active and attempts==5 and cancels==4)
    """)


def native_setup(lua):
    setup(lua)
    lua.execute("""
      s.width=1280;s.height=720;s.platformGeneration=4
      s.modalX=280;s.modalY=92;s.modalWidth=720;s.modalHeight=408
      s.modalAnimation=32;s.modalClosing=0;s.modalBorder=0x200
      local mem={[0x1652740]=2,[0x11265a8]=3,[0x1126600]=0,[0x1fe7d7c]=0,
        [0xb96290]=0x6022f8,[0xb97ad8]=0x602c08,[0x1652744]=1,[0x165274c]=1,
        [0x1652748]=0}
      memory=mem;nativeCalls={};buffer='Previous name'
      package.loaded.ffi={cast=function(kind,value)
        if kind=='int32_t *' then
          return setmetatable({}, {__index=function(_,i) assert(i==0);return assert(mem[value]) end,
            __newindex=function(_,i,v) assert(i==0);mem[value]=v end})
        end
        if kind:find('__thiscall',1,true) then
          return function(owner,index,name)
            assert(owner==0x1652740);nativeCalls[#nativeCalls+1]=value
            if value==0x469800 then assert(index==2 and #name<250);buffer=name
            elseif value==0x469870 then mem[0x1652748]=1
            else error('unexpected native action') end
          end
        end
        return value
      end,string=function(address,size)
        assert(address==0x1652740+0x150+500 and size==250)
        return buffer..string.char(0)..string.rep(' ',249-#buffer)
      end}
      package.loaded['code/native/gameplay']={snapshot=function(value) return value end}
      local scene={snapshot=function() return s end,resolve=function() return facts('game.build') end}
      opens=0;confirmations=0;cancelled=0
      local cursor={}
      function cursor:cancel() self.pending=nil;cancelled=cancelled+1 end
      package.loaded['code/navigation']={new=function(adapter,c)
        assert(c==cursor)
        return {cancel=function() c:cancel() end,
          activateMatching=function(_,selector,context)
            assert(selector.action==0x494950 and selector.parameter==22 and selector.kind==3)
            assert(context.owner=='quickslot.confirm' and context.authority==false)
            assert(adapter.controls(context))
            confirmations=confirmations+1;c.pending={};return true
          end}
      end}
      local world={dispatch=function(_,id,context)
        assert(id=='game.save.open');opens=opens+1
        s.modal=10;s.textModal=10;s.activeModalID=10;s.activeModalMenu=0xb96290
        return true
      end}
      package.loaded['code/native/quickslot']=nil
      q=require('code/native/quickslot').new(scene,{},world,cursor,
        {read=function(_,address,state,origin) assert(address==0xb97ad8 and origin.x==280);return {} end})
      function start() assert(q:start(Context.resolve(facts('game.build')))) end
      function overwrite()
        memory[0x1652748]=0;s.modal=11;s.textModal=11;s.activeModalID=11
        s.activeModalMenu=0xb97ad8;memory[0x1652740]=9;memory[0x1126600]=30
      end
    """)


def test_native_quicksave_uses_text_owner_then_verified_overwrite_control(lua):
    native_setup(lua)
    lua.execute("""
      start();assert(q:context()==nil)
      q:beforeFrame();assert(#nativeCalls==2)
      assert(nativeCalls[1]==0x469800 and nativeCalls[2]==0x469870)
      assert(buffer=='Custom Hotkeys Quick' and memory[0x1652748]==1)
      q:beforeFrame();assert(#nativeCalls==2)
      overwrite();q:beforeFrame();assert(confirmations==1 and q.active)
      q:beforeFrame();assert(confirmations==1)
      s.modal=14;s.textModal=14;s.activeModalID=14;memory[0x1126600]=32
      q:beforeFrame();assert(not q.active and cancelled==1)
    """)


def test_native_quicksave_cancellation_removes_only_its_pending_return(lua):
    native_setup(lua)
    lua.execute("""
      start();memory[0x1652748]=1;q:beforeFrame()
      assert(not q.active and memory[0x1652748]==1 and #nativeCalls==0)
      memory[0x1652748]=0;start();q:beforeFrame();q:cancel()
      assert(memory[0x1652748]==0 and not q.active)
      memory[0x1652748]=1;q:cancel();assert(memory[0x1652748]==1)
    """)


def test_native_quicksave_rejects_other_modals_text_and_focus_generation(lua):
    for field, value in [('focused', False), ('composing', True), ('platformGeneration', 5),
                         ('screen', 16), ('mode', 3), ('player', 2), ('synchronyMode', 1),
                         ('modal2', 11), ('textEditor', 1), ('modalClosing', 1)]:
        native_setup(lua)
        lua.globals().bad_field = field
        lua.globals().bad_value = value
        lua.execute("""
          start();q:beforeFrame();s[bad_field]=bad_value;q:beforeFrame()
          assert(not q.active and memory[0x1652748]==0 and confirmations==0,bad_field)
        """)
    native_setup(lua)
    lua.execute("""
      start();q:beforeFrame();overwrite();memory[0x1126600]=7;q:beforeFrame()
      assert(not q.active and confirmations==0)
      start();q:beforeFrame();overwrite();buffer='Other save';q:beforeFrame()
      assert(not q.active and confirmations==0)
    """)
