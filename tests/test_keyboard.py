def test_modifiers_use_down_bits_and_preserve_right_alt(lua):
    lua.execute('''
      local keyboard=require('code/keyboard')
      local keys={}; for k=0,255 do keys[k]=0 end
      keys[0x11]=1; keys[0x10]=1; keys[0x12]=1
      local s=keyboard.snapshot(keys,false)
      assert(s.mods==0 and not s.altgr and not s.win and not s.composing)
      keys[0xa3]=128; keys[0xa1]=129; keys[0xa4]=128
      s=keyboard.snapshot(keys,false)
      assert(s.mods==7 and not s.altgr)
      keys[0xa5]=128; keys[0xa3]=0; keys[0xa1]=0; keys[0xa4]=0
      s=keyboard.snapshot(keys,true)
      assert(s.mods==4 and s.altgr and s.composing)
      keys[0x5c]=128
      assert(keyboard.snapshot(keys,false).win)
    ''')


def test_missing_release_after_focus_loss_accepts_only_fresh_press(lua):
    lua.execute('''
      assert(router:handle(event(50))); assert(#calls==1)
      router:barrier()
      current.focused=false
      local repeated=event(50); repeated.repeated=true
      assert(router:handle(repeated)); assert(#calls==1)
      current.focused=true
      assert(router:handle(repeated)); assert(#calls==1)
      -- Windows delivered the release elsewhere, then reports a fresh down.
      assert(router:handle(event(50))); assert(#calls==2)
      assert(router:handle(event(50,'char')))
      assert(router:handle(event(50,'up')))
      assert(router:handle(event(50,'char')))
    ''')


def test_duplicate_fresh_down_without_barrier_is_not_second_command(lua):
    lua.execute('''
      assert(router:handle(event(50)))
      assert(router:handle(event(50)))
      assert(#calls==1)
    ''')
