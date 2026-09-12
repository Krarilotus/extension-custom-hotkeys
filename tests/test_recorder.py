def test_absent_old_and_partial_recorder_apis_do_not_block_tester_startup(lua):
    lua.execute('''
      local R=require('code/recorder')
      assert(R.connect({},{}).read()==0)
      assert(R.connect({},{{name='recorder'}}).read()==0)
      local active={{name='recorder'}}
      for _,module in ipairs({{}, {inputStateVersion=2},
          {inputStateVersion=1,getInputState=function() return nil end,
            observeInputTransitions=function() end}}) do
        assert(R.connect({recorder=module},active).read()==0)
      end
    ''')


def test_optional_generation_is_validated_without_blocking_playback(lua):
    lua.execute('''
      local state
      local adapter=require('code/recorder').connect({recorder={inputStateVersion=1,
        getInputState=function() return state end}},{{name='recorder'}})
      for _,bad in ipairs({-1,0.5,math.huge,'1'}) do
        state={generation=bad,blocked=true};assert(adapter.read()==0)
      end
      state={generation=10,blocked=true};assert(adapter.read()==10)
      state={generation=11,blocked=false};assert(adapter.read()==11)
    ''')


def test_transition_releases_old_hold_but_fresh_playback_input_is_available(lua):
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
        local c=facts(); c.generation=adapter.read();return c end,
        dispatch=function() calls=calls+1 end,
        cancelLocalHold=function() cancelled=cancelled+1 end,
        recover=function() end,canRecover=function() return false end})
      adapter.observe(function() router:barrier() end)
      router:handle(event(17));assert(calls==1)
      state={version=1,generation=1,blocked=true};callback()
      assert(cancelled==1)
      router:handle(repeat_event(17));assert(calls==1)
      router:handle(event(17,'up'));router:handle(event(17));assert(calls==2)
      state={version=1,generation=2,blocked=false};callback()
      router:handle(repeat_event(17));assert(calls==2)
      router:handle(event(17,'up'));router:handle(event(17));assert(calls==3)
    ''')
