from test_gameplay import setup


def test_quickload_plan_reaches_every_slot_without_skipping_or_unbounded_clicks(lua):
    lua.execute("""
      local Plan=require('code/quickload_plan')
      for _,count in ipairs({1,15,16,17,31,32,100,499,500}) do
        for offset=0,math.max(0,count-16) do
          for index=0,count-1 do
            local s={loadCount=count,loadRows=16,loadOffset=offset,loadSelected=-1}
            local steps=0
            while true do
              local step=assert(Plan.next(s,index));steps=steps+1
              assert(steps<=49,'bounded native gestures')
              if step.commit then assert(s.loadOffset+s.loadSelected==index);break end
              if step.offset then
                assert(step.offset~=s.loadOffset)
                assert(math.abs(index-step.offset)<math.abs(index-s.loadOffset) or
                  (index>=step.offset and index<step.offset+16))
                assert(step.offset>=0 and step.offset<=math.max(0,count-16))
                s.loadOffset=step.offset
              else s.loadSelected=step.selected end
            end
          end
        end
      end
      local s={loadCount=2,loadRows=16,loadOffset=0,loadSelected=-1}
      for _,index in ipairs({-1,2,1.5,'1',false}) do assert(not Plan.next(s,index)) end
    """)


def test_quickload_workflow_waits_for_gesture_and_never_retries_failure(lua):
    lua.execute("""
      local phase,pending,accept='load',false,true
      local steps,cancels=0,0
      local q=require('code/quickslot').new({
        open=function(_,action) assert(action=='game.quickload');return {} end,
        observe=function() return phase end,
        pending=function() return pending end,
        loadStep=function() steps=steps+1;pending=true;return accept end,
        cancel=function() pending=false;cancels=cancels+1 end})
      assert(q:start({},'game.quickload'));q:beforeFrame()
      for i=1,10 do q:beforeFrame() end
      assert(steps==1)
      pending=false;accept=false;q:beforeFrame();q:beforeFrame()
      assert(not q.active and steps==2 and cancels==1)
      accept=true;assert(q:start({},'game.quickload'));q:beforeFrame()
      phase='progress';q:beforeFrame();assert(not q.active and steps==3)
      phase='load';assert(q:start({},'game.quickload'));q:beforeFrame()
      for i=1,901 do q:beforeFrame() end
      assert(not q.active and steps==4 and cancels==3)
      assert(q:start({},'game.quickload'));phase='name';q:beforeFrame()
      assert(not q.active and steps==4)
    """)


def native_setup(lua):
    setup(lua)
    lua.execute("""
      s.width=1280;s.height=720;s.platformGeneration=4
      s.modalX=280;s.modalY=92;s.modalWidth=720;s.modalHeight=408
      s.modalAnimation=32;s.modalClosing=0;s.modalBorder=0x200
      s.loadArray=0x601a88;s.loadRows=16;s.loadCount=40;s.loadOffset=0;s.loadSelected=-1
      s.loadIdentity='';names={}
      for i=0,39 do
        s.loadIdentity=s.loadIdentity..string.char(i,0,0,0)
        names[i]='Other '..i
      end
      names[39]='Custom Hotkeys Quick'
      local memory={[0x1652740]=4,[0x11265a8]=1,[0x1126600]=0,[0x1fe7d7c]=0}
      package.loaded.ffi={cast=function(kind,address)
        if kind=='int32_t *' then return {[0]=assert(memory[address])} end
        return address
      end,string=function(address,size)
        assert(size==1001)
        local index=(address-0x11bf130-0xbc8)/1001
        local value=assert(names[index])
        return (value..string.char(0)):sub(1,1001)
      end}
      package.loaded['code/native/gameplay']={snapshot=function(value) return value end}
      steps={};cancels=0;pendingCursor={};reject=false
      package.loaded['code/navigation']={new=function(adapter,cursor)
        assert(cursor==pendingCursor)
        return {cancel=function() cursor.pending=nil;cancels=cancels+1 end,
          activateMatching=function(_,selector,context)
            assert(context.owner=='quickslot.load' and not context.authority)
            steps[#steps+1]=selector
            if reject then return false end
            cursor.pending={};return true
          end}
      end}
      local scene={snapshot=function() return s end,resolve=function() return facts('game.build') end}
      local world={dispatch=function(_,id)
        assert(id=='game.load.open');s.modal=9;s.textModal=9;s.activeModalID=9
        s.activeModalMenu=0xb97688;return true
      end}
      q=require('code/native/quickslot').new(scene,{},world,pendingCursor,{})
      function start() assert(q:start(Context.resolve(facts('game.build')),'game.quickload')) end
      function complete()
        local step=steps[#steps]
        if step.offset then s.loadOffset=step.offset end
        if step.selected then s.loadSelected=step.selected end
        pendingCursor.pending=nil
      end
    """)


def test_native_quickload_selects_dedicated_slot_and_commits_once(lua):
    native_setup(lua)
    lua.execute("""
      start();q:beforeFrame()
      assert(steps[1].kind==6 and steps[1].offset==15)
      while not steps[#steps].commit do complete();q:beforeFrame() end
      assert(s.loadOffset+s.loadSelected==39)
      assert(#steps<=12)
      complete();q:beforeFrame();q:beforeFrame()
      assert(not q.active and cancels==1)
      local commits=0;for _,step in ipairs(steps) do if step.commit then commits=commits+1 end end
      assert(commits==1)
    """)


def test_native_quickload_rejects_missing_duplicate_or_changed_name_and_mapping(lua):
    for change in ["names[39]='Absent'", "names[0]='CUSTOM HOTKEYS QUICK'"]:
        native_setup(lua)
        lua.execute(change + ";start();q:beforeFrame();assert(not q.active and #steps==0)")
    for change in ["names[39]='Replaced'", "names[39]=string.rep('x',1001)",
                   "s.loadIdentity=string.char(1,0,0,0)..s.loadIdentity:sub(5)",
                   "s.loadOffset=1", "s.focused=false", "s.textEditor=1",
                   "s.modal2=11", "s.platformGeneration=5"]:
        native_setup(lua)
        lua.execute("start();q:beforeFrame();complete();" + change +
                    ";q:beforeFrame();assert(not q.active and #steps==1)")


def test_native_quickload_refuses_retry_after_rejected_native_gesture(lua):
    native_setup(lua)
    lua.execute("""
      reject=true;start();q:beforeFrame();q:beforeFrame()
      assert(not q.active and #steps==1 and cancels==1)
    """)


def test_quickslot_trigger_debt_and_user_takeover_through_real_message_router(lua):
    lua.execute("""
      local active=false
      local opens,cancels,forwarded=0,0,{}
      local router
      local catalog=Catalog.new(require('code/entries'),require('code/originals'))
      router=Router.new(catalog,Catalog.defaults(catalog),{
        resolve=function() if not active then return facts('game.build') end end,
        dispatch=function(id)
          assert(id=='game.quickload');router:barrier();active=true;opens=opens+1
        end,
        cancelPending=function() if active then active=false;cancels=cancels+1 end end,
        cancelLocalHold=function() end,canRecover=function() return false end,recover=function() end})
      local messages=require('code/messages').new(router,function(_,_,message,key)
        forwarded[#forwarded+1]={message,key};return 99
      end,function() return {mods=1,altgr=false,win=false,composing=false} end,
      function() return true end,function(e)
        if active and (e.kind=='down' or e.kind=='char') then active=false;cancels=cancels+1 end
      end)
      assert(messages(1,1,0x100,76,38*65536)==0 and opens==1 and active)
      assert(messages(1,1,0x100,76,38*65536+1073741824)==0 and opens==1 and active)
      assert(messages(1,1,0x101,76,38*65536+3221225472)==0 and active)
      assert(messages(1,1,0x102,12,38*65536)==0 and active)
      assert(messages(1,1,0x101,17,29*65536+3221225472)==99 and active)
      assert(messages(1,1,0x100,65,30*65536)==99 and not active and cancels==1)
      assert(#forwarded==2 and forwarded[2][2]==65)
      assert(messages(1,1,0x100,76,38*65536)==0 and opens==2)
      messages(1,1,0x8,0,0)
      assert(not active and cancels==2)
    """)
