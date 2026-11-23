def test_apply_routes_exactly_what_the_next_launch_derives(lua):
    # An inherited action that lost its chord to an explicit one gets it
    # back as soon as the explicit entry moves away.
    lua.execute('''
      local config=memoryConfig()
      config.tree={bindings={['custom-hotkeys']={unit={move=key(30)}}}}
      local profiles=config:open(catalog,router)
      assert(profiles.committed.bindings['camera.left']==false)
      profiles:begin();assert(profiles:bind('unit.move',false));assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==30)
      local restarted=config:open(catalog,router)
      for id,binding in pairs(restarted.committed.bindings) do
        assert(Binding.equal(binding,profiles.committed.bindings[id]),id)
      end
    ''')


def test_a_set_aside_entry_returns_once_its_chord_is_free_and_a_swap_replaces_it(lua):
    lua.execute('''
      local config=memoryConfig()
      config.tree={bindings={['custom-hotkeys']={unit={move=key(30)},camera={left=key(30)}}}}
      local b=config:open(catalog,router)
      assert(#b.committed.aside==1 and b.committed.aside[1]=='unit.move')
      assert(b.committed.bindings['unit.move']==false)
      b:begin();assert(b:bind('market.buy',key(30)))
      assert(b.draft.explicit['unit.move'].scan==30)
      assert(b:bind('camera.left',key(31)))
      assert(b.draft.bindings['unit.move'].scan==30 and #b.draft.aside==0)
      local c=Catalog.new({
        {id='game.a',contexts={'game'},states={'live-sp'},command=false,default=key(10)},
        {id='game.b',contexts={'game'},states={'live-sp'},command=false,default=key(11)},
        {id='game.c',contexts={'game'},states={'live-sp'},command=false,default=key(12)}})
      local tree={bindings={['custom-hotkeys']={game={a=key(30),b=key(30)}}}}
      b=Bindings.new(c,Bindings.source(c,tree,tree),memoryConfig(),Router.new(c,Catalog.defaults(c),adapter))
      assert(b.committed.aside[1]=='game.b')
      b:begin();assert(b:reassign('game.c',key(30),'game.a',key(12)))
      assert(b.draft.bindings['game.c'].scan==30 and b.draft.bindings['game.b'].scan==11)
      assert(b.draft.explicit['game.b']==nil)
    ''')


def test_suggestions_resolve_together_before_layout_defaults_and_reset_always_inherits(lua):
    lua.execute('''
      local source=Bindings.source(catalog,{},{bindings={['custom-hotkeys']={
        unit={move=key(30)},camera={left=false}}}})
      local b=Bindings.new(catalog,source,memoryConfig(),router)
      assert(b.committed.bindings['unit.move'].scan==30 and b.committed.bindings['camera.left']==false)
      local tree={bindings={['custom-hotkeys']={unit={move=key(30)}}}}
      b=Bindings.new(catalog,Bindings.source(catalog,tree,tree),memoryConfig(),router)
      b:begin();assert(b:bind('camera.left',key(31)));assert(b:bind('unit.move',key(32)))
      assert(b:reset('camera.left') and b.draft.bindings['camera.left'].scan==30)
      assert(b:bind('unit.move',key(30))==nil)
      assert(b:reset('unit.move') and b.draft.bindings['unit.move'].scan==50)
    ''')


def test_launcher_required_values_win_and_cannot_be_edited(lua):
    # The launcher writes a required value into config-full only.
    lua.execute('''
      local source=Bindings.source(catalog,
        {bindings={['custom-hotkeys']={unit={move=key(21)}}},layout='grid'},
        {bindings={['custom-hotkeys']={unit={move=key(22)}}},layout='custom'})
      assert(source.locked['unit.move'] and source.explicit['unit.move'].scan==22)
      assert(source.layoutLocked and source.layout=='custom')
      local config=memoryConfig()
      local b=Bindings.new(catalog,source,config,router)
      assert(b.committed.bindings['unit.move'].scan==22)
      b:begin()
      assert(select(2,b:bind('unit.move',key(23)))=='binding.locked')
      assert(select(2,b:reset('unit.move'))=='binding.locked')
      assert(select(2,b:select('grid'))=='binding.locked')
      assert(b:reset() and b.draft.explicit['unit.move'].scan==22)
      assert(b:apply() and #config.saves==0)
    ''')


def test_config_wrapper_and_owner_names_are_not_provider_ids(lua):
    lua.execute('''
      assert(Catalog.extensionId('ext.zoom.in'))
      for _,id in ipairs({'ext.contents.in','ext.zoom.contents','ext.custom-hotkeys.in',
          'ext.constructor.in','ext.zoom.constructor'}) do
        assert(not Catalog.extensionId(id),id)
      end
    ''')


def test_parked_provider_chords_migrate_and_existing_config_paths_win(lua):
    lua.execute('''
      local Legacy=require('code/legacy_profiles')
      local c=Catalog.production()
      local doc={schema=3,active='Mine',profiles={Mine={preset='game-default',
        bindings={['ext.zoom.in']=false,['ext.zoom.out']=false,['ext.gone.act']=key(40)},
        unavailable={['ext.zoom.in']={wheel='up',mods=1}}}}}
      local migrated=Legacy.explicit(c,doc)
      assert(migrated.explicit['ext.zoom.in'].wheel=='up' and migrated.explicit['ext.zoom.out']==false)
      local unclaimed=Bindings.unclaimed(migrated,{bindings={gone={act=false}},layout='grid'})
      assert(unclaimed.explicit['ext.gone.act']==nil and unclaimed.layout==nil)
      assert(unclaimed.explicit['ext.zoom.in'].wheel=='up')
    ''')


def test_a_failed_migration_write_is_written_by_the_next_apply(lua):
    lua.execute('''
      local c=Catalog.production()
      local config=memoryConfig();config.failed=true
      local source=Bindings.source(c,{},{})
      source.legacy={layout='game-default',explicit={['game.quicksave']=key(65,1),['ext.gone.act']=key(40)}}
      local r=Router.new(c,Catalog.defaults(c),adapter)
      local b=Bindings.new(c,source,config,r)
      assert(not b.migration.saved and r.bindings['game.quicksave'].scan==65)
      config.failed=false
      b:begin();assert(b:bind('game.quickload',key(66,1)));assert(b:apply())
      local written={}
      for _,change in ipairs(config.saves[1]) do written[table.concat(change.path,'.')]=true end
      assert(written['bindings.custom-hotkeys.game.quicksave'] and written['bindings.gone.act'])
      assert(written['bindings.custom-hotkeys.game.quickload'])
    ''')


def test_retire_moves_both_slots_or_neither(lua):
    lua.execute('''
      local B=require('code/ucp_storage')
      local present={['ucp/custom-hotkeys-profiles-a.json']=true,['ucp/custom-hotkeys-profiles-b.json']=true}
      local io={open=function(path) if present[path] then return {close=function() end} end end}
      local log={}
      local fs={remove=function() end,rename=function(from,to)
        if from:find('profiles%-b%.json$') then return nil,'denied' end
        log[#log+1]=from..'>'..to;return true end}
      local ok,err=B.new(io,fs).retire()
      assert(not ok and err=='store.retire')
      assert(log[1]=='ucp/custom-hotkeys-profiles-a.json>ucp/custom-hotkeys-profiles-a.json.migrated')
      assert(log[2]=='ucp/custom-hotkeys-profiles-a.json.migrated>ucp/custom-hotkeys-profiles-a.json')
    ''')


def test_a_required_value_outranks_explicit_entries_and_survives_a_swap(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='game.a',contexts={'game'},states={'live-sp'},command=false,default=key(10)},
        {id='game.b',contexts={'game'},states={'live-sp'},command=false,default=key(11)},
        {id='game.c',contexts={'game'},states={'live-sp'},command=false,default=key(12)}})
      local source=Bindings.source(c,{bindings={['custom-hotkeys']={game={a=key(14),b=key(13)}}}},
        {bindings={['custom-hotkeys']={game={a=key(14),b=key(14)}}}})
      assert(source.locked['game.b'])
      local config=memoryConfig()
      local b=Bindings.new(c,source,config,Router.new(c,Catalog.defaults(c),adapter))
      assert(b.committed.bindings['game.b'].scan==14 and b.committed.bindings['game.a']==false)
      b:begin();assert(b:reassign('game.c',key(14),'game.a',key(12))==nil)
      assert(b.draft.explicit['game.b'].scan==14)
      assert(b:bind('game.a',key(15)) and b:apply())
      for _,change in ipairs(config.saves[1]) do assert(change.path[#change.path]~='b') end
    ''')


def test_an_action_displaced_by_a_loser_gets_its_chord_back(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='world.default',contexts={'game'},states={'live-sp','editor'},command=false,default=key(20)},
        {id='both.suggested',contexts={'game','editor'},states={'live-sp','editor'},command=false,default=false},
        {id='editor.explicit',contexts={'editor'},states={'live-sp','editor'},command=false,default=false}})
      local bindings,aside=Bindings.resolve(c,nil,{['both.suggested']=key(20)},{['editor.explicit']=key(20)})
      assert(bindings['world.default'].scan==20 and bindings['both.suggested']==false)
      assert(bindings['editor.explicit'].scan==20 and #aside==0)
    ''')


def test_retirement_moves_the_newer_slot_last(lua):
    lua.execute('''
      local B=require('code/ucp_storage')
      local present={['ucp/custom-hotkeys-profiles-a.json']=true,['ucp/custom-hotkeys-profiles-b.json']=true}
      local io={open=function(path) if present[path] then return {close=function() end} end end}
      local log={}
      local fs={remove=function() end,rename=function(from) log[#log+1]=from;return true end}
      assert(B.new(io,fs).retire('a'))
      assert(log[1]:find('profiles%-b') and log[2]:find('profiles%-a'))
    ''')
