def test_absent_recorder_is_optional_and_old_or_failed_api_is_rejected(lua):
    lua.execute('''
      local R=require('code/recorder')
      assert(not R.connect({},{}).read().blocked)
      local active={{name='recorder'}}
      for _,module in ipairs({{}, {inputStateVersion=2},
          {inputStateVersion=1,getInputState=function() return nil end,
            observeInputTransitions=function() end}}) do
        assert(not pcall(R.connect,{recorder=module},active))
      end
    ''')


def test_state_validation_rejects_ambiguous_authority(lua):
    lua.execute('''
      local valid=require('code/recorder_context').validate
      assert(valid({version=1,generation=0,blocked=false}))
      assert(valid({version=1,generation=10,blocked=true}))
      for _,s in ipairs({{}, {version=1,generation=0},
          {version=1,generation=-1,blocked=false},
          {version=1,generation=0.5,blocked=false},
          {version=1,generation=0,blocked=0}}) do assert(not valid(s)) end
    ''')


def test_live_getter_is_not_cached_and_observer_cancels_held_input(lua):
    lua.execute('''
      local R=require('code/recorder')
      local state={version=1,generation=0,blocked=false}
      local callback
      local owner={inputStateVersion=1,getInputState=function() return state end,
        observeInputTransitions=function(_,fn) callback=fn;return function() callback=nil end end}
      local adapter=R.connect({recorder=owner},{{name='recorder'}})
      local calls,cancelled=0,0
      local catalog=Catalog.new({{id='pan',contexts={'game'},states={'live-sp'},
        command=false,behavior='hold-local',default=key(17)}})
      local router=Router.new(catalog,{pan=key(17)},{resolve=function()
        local s=adapter.read(); if s.blocked then return nil end
        local c=facts(); c.generation=s.generation;return c end,
        dispatch=function() calls=calls+1 end,
        cancelLocalHold=function() cancelled=cancelled+1 end,
        recover=function() end,canRecover=function() return false end})
      adapter.observe(function() router:barrier() end)
      router:handle(event(17));assert(calls==1)
      state={version=1,generation=1,blocked=true};callback()
      assert(cancelled==1)
      router:handle(repeat_event(17));assert(calls==1)
      state={version=1,generation=2,blocked=false};callback()
      router:handle(repeat_event(17));assert(calls==1)
      router:handle(event(17,'up'));router:handle(event(17));assert(calls==2)
    ''')
