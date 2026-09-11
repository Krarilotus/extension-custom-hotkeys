from test_cursor import setup


def test_target_movement_is_visible_bounded_and_never_an_action(lua):
    setup(lua)
    lua.execute('''
      raw.owner='game.build';raw.state='live-sp';current=Context.resolve(raw)
      local left,top,width,height=0,0,800,480
      target=require('code/targeting').new(cursor,{cancel=function() cursor:cancel() end},
        function() return left,top,width,height end)
      assert(target:dispatch('target.center',current));assert(x==400 and y==240)
      assert(target:dispatch('target.right',current));assert(x==424 and y==240)
      assert(target:dispatch('target.fine.left',current));assert(x==423 and y==240)
      x,y=799,479
      assert(target:dispatch('target.down',current));assert(x==775 and y==455 and #changes==0)
      raw.owner='menu.main';current=Context.resolve(raw)
      assert(not target:dispatch('target.confirm',current) and #changes==0)
    ''')


def test_target_confirm_cannot_hit_footer_or_leak_across_changed_projection(lua):
    setup(lua)
    lua.execute('''
      raw.owner='game.build';raw.state='live-sp';current=Context.resolve(raw)
      local projection='camera:0'
      target=require('code/targeting').new(cursor,{cancel=function() cursor:cancel() end},
        function() return 0,0,800,480,projection end)
      y=550;assert(not target:dispatch('target.confirm',current))
      y=240;assert(target:dispatch('target.confirm',current))
      assert(not target:dispatch('target.confirm',current))
      cursor:beforeFrame();projection='camera:1';cursor:beforeFrame()
      assert(#changes==0 and not cursor.pending)
      current=Context.resolve(raw);assert(target:dispatch('target.cancel',current))
      for i=1,4 do cursor:beforeFrame() end
      assert(#changes==2 and changes[1][1]=='right' and changes[1][2] and not changes[2][2])
    ''')
