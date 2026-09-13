def test_same_key_uses_actual_owner_and_state_and_rechecks_authority(lua):
    lua.execute('''
      local entries={}
      for i=1,400 do
        entries[i]={id='action.'..i,contexts={'panel.'..i},states={'live-sp'},
          command=true,default=key(50)}
      end
      entries[401]={id='viewer',contexts={'panel.400'},states={'replay'},
        command=false,default=key(50)}
      local c=Catalog.new(entries)
      local r=Router.new(c,Catalog.defaults(c),adapter)
      current.owner='panel.400'
      assert(r:handle(event(50)));r:handle(event(50,'up'))
      assert(calls[1]=='action.400')
      current.state='replay'
      assert(r:handle(event(50)));r:handle(event(50,'up'))
      assert(calls[2]=='viewer')
      current.state='live-sp';current.authority=false
      assert(not r:handle(event(50)));r:handle(event(50,'up'))
      current.authority=true;current.owner='panel.1'
      assert(r:handle(event(50)));r:handle(event(50,'up'))
      assert(calls[3]=='action.1' and #calls==3)
      local bindings=Catalog.defaults(c);bindings['action.1']=false
      assert(r:apply(bindings))
      assert(not r:handle(event(50)))
    ''')
