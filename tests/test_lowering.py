def setup(lua):
    lua.execute("""
      raw=facts('game.build');local c=Context.resolve(raw)
      modes={};flag=false;nativeV=false;other=false;available=true
      adapter={resolve=function() return raw end,available=function() return available end,
        setV=function(value) flag=value end,
        lower=function(mode) modes[#modes+1]=mode end,
        nativeVHeld=function() return nativeV end,otherNativeHold=function() return other end}
      lowering=require('code/lowering').new(adapter)
      function start() return lowering:start(Context.resolve(raw)) end
    """)


def test_lowering_reuses_native_entry_once_and_restores_owned_hold(lua):
    setup(lua)
    lua.execute("""
      assert(start() and flag and modes[1]==3)
      assert(not start())
      for i=1,20 do
        flag=false -- Original modifier poll precedes input-frame hook.
        lowering:beforeFrame(Context.resolve(raw));assert(flag)
      end
      assert(#modes==1)
      lowering:release();assert(not flag and not lowering.active and modes[2]==4)
      lowering:release();lowering:beforeFrame(Context.resolve(raw));assert(#modes==2)
      available=false;assert(not start() and #modes==2)
    """)


def test_lowering_cancels_for_text_modal_focus_and_generation_changes(lua):
    setup(lua)
    lua.execute("""
      local changes={text=true,focused=false,composing=true,generation=2,
        modal='Save',screen='other',selection='changed',targeting='rotated',state='replay'}
      for field,value in pairs(changes) do
        raw=facts('game.build');assert(start())
        raw[field]=value;lowering:beforeFrame(Context.resolve(raw))
        assert(not lowering.active and not flag and modes[#modes]==4,field)
      end
      for _,owner in ipairs({'game.load','game.options','hotkeys.editor','menu.main'}) do
        raw=facts(owner);assert(not start())
      end
      raw=facts('game.build','live-mp');assert(not start())
    """)


def test_lowering_release_preserves_other_native_input_owners(lua):
    setup(lua)
    lua.execute("""
      assert(start());nativeV=true;lowering:release()
      assert(flag and #modes==1 and not lowering.active)
      nativeV=false;flag=false;assert(start());other=true;lowering:release()
      assert(not flag and #modes==2 and not lowering.active)
      other=false;assert(start());lowering:release();assert(modes[#modes]==4)
    """)


def test_uncertain_native_lowering_entry_can_be_cancelled_without_retry(lua):
    setup(lua)
    lua.execute("""
      adapter.lower=function(mode)
        modes[#modes+1]=mode;if mode==3 then error('uncertain') end
      end
      assert(not pcall(start) and lowering.active)
      lowering:release();assert(not lowering.active and not flag and #modes==2)
      lowering:release();assert(#modes==2)
    """)


def test_native_lowering_uses_original_handler_and_proves_forwarded_v(lua):
    lua.execute("""
      raw=facts('game.build');memory={[0xf224fc]=0,[0xf224ec]=0,[0xf224f8]=0,
        [0xf2c9f8]=0,[0x1387f38]=100};modes={};down=true
      package.loaded.ffi={cast=function(kind,address)
        if kind=='int32_t *' then
          return setmetatable({}, {__index=function(_,i) assert(i==0);return assert(memory[address]) end,
            __newindex=function(_,i,value) assert(i==0);memory[address]=value end})
        end
        if kind:find('__thiscall',1,true) then
          assert(address==0x4f6fd0)
          return function(owner,mode) assert(owner==0x1a93208);modes[#modes+1]=mode end
        end
        return address
      end}
      local router={held={},readContext=function() return Context.resolve(raw) end}
      local platform={keyDown=function(_,vk) assert(vk==0x56 or vk==0x11 or vk==0x28);return down end}
      local scene={resolve=function() return raw end}
      local q=require('code/native/lowering').new(scene,{},platform,router)
      local c=Context.resolve(raw)
      assert(q:start(c));assert(memory[0xf224fc]==1 and modes[1]==3)
      router.held[47]={consumed=false,blocked=false};q:release()
      assert(memory[0xf224fc]==1 and #modes==1)
      memory[0xf224fc]=0;assert(q:start(c));router.held[47].blocked=true;q:release()
      assert(memory[0xf224fc]==0 and modes[#modes]==4)
      memory[0xf2c9f8]=1;assert(not q:start(c));memory[0xf2c9f8]=0
      memory[0x1387f38]=2501;assert(not q:start(c));memory[0x1387f38]=100
      assert(q:start(c));memory[0xf224ec]=1;memory[0xf224f8]=1
      router.held[208]={consumed=false,blocked=false};q:release()
      assert(memory[0xf224fc]==0 and modes[#modes]==3)
      assert(q:start(c));router.held[208].blocked=true;q:release()
      assert(modes[#modes]==4)
      assert(q:start(c));memory[0xf2c9f8]=1;raw.focused=false;q:release()
      assert(memory[0xf224fc]==0 and modes[#modes]==4)
    """)


def test_existing_input_frame_skips_idle_and_refreshes_shared_hold_context_once(lua):
    lua.execute("""
      package.loaded.ffi={cast=function(kind,value)
        if kind=='uintptr_t' then return 123 end
        return value
      end}
      remote={interface={installInputFrame=function(pointer) assert(pointer==123);return 456 end}}
      local refresh,frames,pan=0,0,0
      local camera={count=0,beforeFrame=function() pan=pan+1 end}
      local lowering={active=false,beforeFrame=function(_,context) assert(context=='current');frames=frames+1 end}
      local router={refresh=function() refresh=refresh+1;return 'current' end}
      local frame=require('code/native/input_frame').install({},router,camera,{},lowering)
      frame.callback(0xf2c9b0);assert(refresh==0 and frames==0)
      lowering.active=true;frame.callback(0xf2c9b0)
      assert(refresh==1 and frames==1)
      camera.count=1;frame.callback(0xf2c9b0)
      assert(refresh==2 and frames==2 and pan==1)
      frame.callback(0);assert(refresh==2)
    """)


def test_failed_native_ownership_probe_still_clears_our_lowering_flag(lua):
    setup(lua)
    lua.execute("""
      assert(start())
      adapter.nativeVHeld=function() error('keyboard snapshot failed') end
      assert(not pcall(lowering.release,lowering))
      assert(not lowering.active and not flag)
      lowering:release();assert(not flag)
    """)
