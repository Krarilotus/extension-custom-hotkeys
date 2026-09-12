def test_semantic_groups_are_complete_contiguous_and_independent_of_labels(lua):
    lua.execute('''
      local c=Catalog.production();local source=Catalog.defaults(c)
      local seen,groups={},{};local last
      assert(#c.editorOrdered==#c.ordered)
      for _,a in ipairs(c.editorOrdered) do
        assert(not seen[a.id]);seen[a.id]=true
        if a.group~=last then
          assert(not groups[a.group]);groups[a.group]=true;last=a.group
        end
      end
      assert(c.actions['unit.group.assign.1'].group=='selection')
      assert(c.actions['unit.group.recall.1'].group=='selection')
      assert(c.actions['camera.group.1'].group=='selection')
      assert(c.actions['camera.return.armory'].group=='buildings')
      assert(c.actions['menu.open.armory'].group=='buildings')
      local store={load=function() return nil,'store.missing' end,save=function() return true end}
      local p=assert(Profiles.new(c,store,Router.new(c,source,adapter)))
      local e=require('code/editor').new(p,c,router,function(id) return 'ZZ '..id end,string.lower,16)
      e:filter('','selection');assert(e:view().total==32)
      local v=e:view();assert(v.rows[1].sectionStart and not v.rows[2].sectionStart)
      e:scroll(5);assert(e:view().rows[1].sectionStart)
      e:filter('camera.group.','selection');assert(e:view().total==10)
      for id,b in pairs(source) do
        assert((not b and not c.actions[id].default) or Binding.same(b,c.actions[id].default))
      end
    ''')


def test_native_number_defaults_are_visible_and_forwarded_once_in_every_preset(lua):
    lua.execute('''
      local c=Catalog.production()
      local store={load=function() return nil,'store.missing' end,save=function() return true end}
      local p=assert(Profiles.new(c,store,Router.new(c,Catalog.defaults(c),adapter)))
      local e=require('code/editor').new(p,c,router,function(id) return id end,string.lower,16)
      for _,preset in ipairs(c.presetOrder) do
        assert(e:selectProfile(preset.name))
        local r=Router.new(c,p.draft.profiles[p.draft.active].bindings,adapter)
        current=facts('game.build')
        for n=0,9 do
          local scan=n==0 and 11 or n+1
          e:filter('unit.group.recall.'..n)
          local row=e:view().rows[1]
          assert(not row.binding and row.nativeFallback.label=='nativeKey')
          assert(row.nativeFallback.binding.scan==scan and row.nativeFallback.binding.mods==0)
          assert(not r:handle(event(scan)) and not r:handle(event(scan,'up')))
          assert(not r:handle(event(scan)) and not r:handle(event(scan,'up')))
          e:filter('camera.group.'..n)
          assert(e:view().rows[1].nativeFallback.label=='nativeAgain')
          assert(e:clear())
          assert(e:view().rows[1].nativeFallback.label=='nativeAgain')
        end
      end
      assert(#calls==0) -- no parallel custom dispatch of retained native numbers
    ''')
