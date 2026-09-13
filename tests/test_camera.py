def setup(lua):
    lua.execute('''
      local Camera=require('code/camera')
      raw=facts('game.build');flags={};writes=0;nativeHeld=false
      camera=Camera.new({set=function(direction,value) flags[direction]=value;writes=writes+1 end,
        nativeHeld=function() return nativeHeld end})
      local catalog=Catalog.new({{id='camera.pan.up',contexts={'game.build'},
        states={'live-sp'},command=false,behavior='hold-local',default=key(17)}})
      router=Router.new(catalog,Catalog.defaults(catalog),{
        resolve=function() return raw end,dispatch=function(id,c) return camera:start(id,c) end,
        canRecover=function() return false end,recover=function() end,
        cancelLocalHold=function(id) camera:release(id) end})
    ''')


def test_camera_hold_survives_native_pan_but_not_focus_modal_or_selection(lua):
    setup(lua)
    lua.execute('''
      assert(router:handle(event(17)));assert(flags.up and camera.count==1)
      raw.cameraX=32
      camera:beforeFrame(router:refresh());assert(flags.up and camera.count==1)
      assert(router:handle(repeat_event(17)));assert(camera.count==1)
      raw.text=true
      camera:beforeFrame(router:refresh());assert(not flags.up and camera.count==0)
      raw.text=false;camera:beforeFrame(router:refresh())
      assert(router:handle(repeat_event(17)));assert(not flags.up)
      assert(router:handle(event(17,'up')))
      assert(router:handle(event(17)));raw.selection='another-unit'
      camera:beforeFrame(router:refresh());assert(not flags.up)
    ''')


def test_release_one_direction_or_one_alias_preserves_other_holds(lua):
    setup(lua)
    lua.execute('''
      local c=Context.resolve(raw)
      assert(camera:start('camera.pan.up',c))
      assert(camera:start('camera.pan.up.alternate',c))
      assert(camera:start('camera.pan.left',c))
      camera:release('camera.pan.up');assert(flags.up and flags.left)
      camera:release('camera.pan.up.alternate');assert(not flags.up and flags.left)
      nativeHeld=true;camera:release('camera.pan.left');assert(flags.left and camera.count==0)
      local before=writes;camera:release('camera.pan.left');assert(writes==before)
    ''')


def test_profile_apply_cancels_local_pan_without_new_command(lua):
    setup(lua)
    lua.execute('''
      assert(router:handle(event(17)) and flags.up)
      assert(router:apply({['camera.pan.up']=key(18)}))
      assert(not flags.up and camera.count==0)
      assert(router:handle(repeat_event(17)) and not flags.up)
      assert(router:handle(event(17,'up')) and not flags.up)
    ''')


def test_transition_revokes_all_gestures_before_any_native_cancellation(lua):
    lua.execute("""
      for _,transition in ipairs({'barrier','refresh','apply','capture'}) do
        local raw=facts('game.build')
        local router,exposed,releases=nil,false,0
        local catalog=Catalog.new({
          {id='camera.pan.up',contexts={'game.build'},states={'live-sp'},
           command=false,behavior='hold-local',default=key(17)},
          {id='camera.pan.left',contexts={'game.build'},states={'live-sp'},
           command=false,behavior='hold-local',default=key(30)}})
        local function observeCancellation()
          for _,held in pairs(router and router.held or {}) do
            if not held.blocked then exposed=true end
          end
        end
        router=Router.new(catalog,Catalog.defaults(catalog),{
          resolve=function() return raw end,dispatch=function() return true end,
          recover=function() end,canRecover=function() return false end,
          cancelPending=observeCancellation,
          cancelLocalHold=function() releases=releases+1;observeCancellation() end})
        assert(router:handle(event(17)));assert(router:handle(event(30)))
        assert(not router:handle(event(72))) -- A forwarded native arrow also owns input.
        exposed=false
        if transition=='barrier' then router:barrier()
        elseif transition=='refresh' then raw.text=true;router:refresh()
        elseif transition=='apply' then assert(router:apply(Catalog.defaults(catalog)))
        else router:startCapture(function() end) end
        assert(not exposed,'cancellation exposed an old gesture: '..transition)
        assert(releases==2 and not router.blocked)
        assert(router:handle(event(17,'up')) and router:handle(event(30,'up')))
        assert(not router:handle(event(72,'up'))) -- Preserve native release forwarding.
        assert(releases==2)
      end
    """)
