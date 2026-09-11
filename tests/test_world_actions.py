def setup(lua):
    lua.execute('''
      raw=facts('game.build');raw.screen='14';raw.panel='61:0'
      c=Context.resolve(raw);calls={};s={screen=14,tab=61,selectedCount=1,tribe=0,tribeOwner=1,player=1}
      b={id=10,type=11,owner=1,x=50,y=60};mark=-1;index=0;posts={}
      world=require('code/world_actions').new({resolve=function() return raw end,
        snapshot=function() return s end,
        stance=function(tribe,value) calls[#calls+1]={'stance',tribe,value} end,
        building=function() return b end,
        bookmark=function(_,v) if v~=nil then mark=v end;return mark end,
        viewportTile=function() return 321 end,
        focus=function(x,y) calls[#calls+1]={'focus',x,y} end,
        focusTile=function(tile) calls[#calls+1]={'tile',tile} end,
        openBuilding=function(id) calls[#calls+1]={'open',id};return true end,
        buildScreen=function() calls[#calls+1]={'build'} end,
        signpostIndex=function(v) if v~=nil then index=v end;return index end,
        signpost=function(i) return posts[i] end})
    ''')


def test_stance_uses_one_submission_and_rejects_wrong_panel_owner_or_selection(lua):
    setup(lua)
    lua.execute('''
      assert(world:dispatch('unit.stance.defensive',c));assert(#calls==1)
      assert(calls[1][1]=='stance' and calls[1][2]==0 and calls[1][3]==1)
      for field,value in pairs({screen=16,tab=48,selectedCount=0,tribe=1250,tribeOwner=2}) do
        local old=s[field];s[field]=value
        assert(not world:dispatch('unit.stance.defensive',c));s[field]=old
      end
      for field,value in pairs({text=true,modal='5',state='replay',authority=false,selection='changed'}) do
        local old=raw[field];raw[field]=value
        assert(not world:dispatch('unit.stance.defensive',c));raw[field]=old
      end
      assert(#calls==1)
    ''')


def test_armory_focus_open_and_return_preserve_distinct_original_semantics(lua):
    setup(lua)
    lua.execute('''
      assert(world:dispatch('menu.open.armory',c));assert(#calls==1 and mark==-1)
      assert(world:dispatch('menu.focus.armory',c));assert(mark==321 and #calls==3)
      assert(calls[2][1]=='focus' and calls[2][2]==52 and calls[2][3]==62)
      assert(calls[3][1]=='open' and calls[3][2]==10)
      s.screen=16;raw.screen='16';raw.owner='game.status';c=Context.resolve(raw)
      assert(world:dispatch('camera.return.armory',c))
      assert(mark==-1 and calls[4][1]=='tile' and calls[5][1]=='build')
      assert(not world:dispatch('camera.return.armory',c))
      b.owner=2;assert(not world:dispatch('menu.open.armory',c))
      b.owner=1;b.type=10;assert(not world:dispatch('menu.focus.armory',c))
      assert(#calls==5)
    ''')


def test_signpost_cycle_is_bounded_and_skips_missing_or_reused_buildings(lua):
    setup(lua)
    lua.execute('''
      assert(world:dispatch('camera.cycle.signposts',c));assert(index==0 and #calls==0)
      posts[0]={id=20,type=52,x=10,y=20};posts[3]={id=21,type=11,x=1,y=1}
      posts[5]={id=22,type=52,x=30,y=40}
      assert(world:dispatch('camera.cycle.signposts',c));assert(index==5 and #calls==1)
      assert(calls[1][2]==11 and calls[1][3]==21)
      assert(world:dispatch('camera.cycle.signposts',c));assert(index==0 and #calls==2)
      index=8;assert(not world:dispatch('camera.cycle.signposts',c) and #calls==2)
    ''')


def test_building_shortcuts_keep_separate_bookmarks_and_validate_current_owner(lua):
    setup(lua)
    lua.execute('''
      local marks={}
      world.adapter.bookmark=function(spec,v)
        if v~=nil then marks[spec.name]=v end
        return marks[spec.name] or -1
      end
      for _,spec in ipairs(require('code/building_actions')) do
        b.type=spec.types[1];b.owner=1
        local before=#calls
        assert(world:dispatch('menu.open.'..spec.name,c))
        assert(#calls==before+1 and calls[#calls][1]=='open' and marks[spec.name]==nil)
        b.owner=2;assert(not world:dispatch('menu.open.'..spec.name,c));b.owner=1
        b.type=99;assert(not world:dispatch('menu.open.'..spec.name,c));b.type=spec.types[1]
        raw.modal='covered';assert(not world:dispatch('menu.open.'..spec.name,c));raw.modal=''
        if spec.bookmark then
          assert(world:dispatch('menu.focus.'..spec.name,c));assert(marks[spec.name]==321)
        else assert(not world:dispatch('menu.focus.'..spec.name,c)) end
      end
      assert(world:dispatch('camera.return.granary',c))
      assert(marks.granary==-1 and marks.armory==321 and marks.market==321)
      b.type=26;b.x=400
      assert(not world:dispatch('menu.focus.market',c))
      assert(marks.market==321)
      assert(world:dispatch('menu.open.market',c)) -- Opening does not move the camera.
    ''')


def test_production_defaults_require_displaced_actions_and_retain_native_arrows(lua):
    lua.execute('''
      local catalog=Catalog.new(require('code/entries'),require('code/originals'))
      local defaults=assert(Catalog.validate(catalog,Catalog.defaults(catalog)))
      defaults['view.toggle-interface']=false
      assert(not Catalog.validate(catalog,defaults))
      defaults=Catalog.defaults(catalog)
      defaults['menu.focus.armory']=false
      local ok,reason=Catalog.validate(catalog,defaults)
      assert(not ok and reason=='binding.native-conflict')
      defaults=Catalog.defaults(catalog);defaults['unit.stance.defensive']=false
      assert(not Catalog.validate(catalog,defaults))
      defaults=Catalog.defaults(catalog)
      current=facts('game.build');current.screen='14';current.panel='48:0'
      local count=0
      local router=Router.new(catalog,defaults,{resolve=function() return current end,
        dispatch=function() count=count+1 end,cancelLocalHold=function() end,
        canRecover=function() return false end,recover=function() end})
      local arrow=event(72);arrow.extended=true
      assert(not router:handle(arrow) and count==0)
      assert(router:handle(event(17)));assert(router:handle(repeat_event(17)) and count==1)
      assert(router:handle(event(17,'up')))
      assert(router:handle(event(17,'down',4)) and count==2)
    ''')


def test_toolbar_replacement_uses_native_action_only_in_eligible_build_screen(lua):
    setup(lua)
    lua.execute('''
      local toggles=0
      world.adapter.toggleInterface=function() toggles=toggles+1 end
      assert(world:dispatch('view.toggle-interface',c));assert(toggles==1)
      s.screen=16;assert(not world:dispatch('view.toggle-interface',c));s.screen=14
      raw.text=true;assert(not world:dispatch('view.toggle-interface',c));raw.text=false
      raw.modal='5';assert(not world:dispatch('view.toggle-interface',c));raw.modal=''
      raw.generation=2;assert(not world:dispatch('view.toggle-interface',c))
      assert(toggles==1)
    ''')
